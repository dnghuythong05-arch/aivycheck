(() => {
  'use strict';

  const BASE =
    'https://cdn.jsdelivr.net/npm/@vladmandic/human@3.3.6/';

  const MODEL = 'human-3.3.6-faceres';
  const PREPROCESSING = 'equalized-v1';
  const MATCH_THRESHOLD = 0.65;

  const MAX_REFERENCE_PHOTOS = 10;
  const API_VERSION = 2;
  const MAX_PREVIEW_CHARS = 60000;

  const VERIFY_WINDOW_MS = 15000;
  const SAMPLE_INTERVAL_MS = 400;
  const REQUIRED_SAMPLES = 3;

  let engineTask;
  let active = false;
  let inference = Promise.resolve();

  class FaceFrameError extends Error {}

  function validSamples(samples) {
    return Array.isArray(samples) &&
      samples.length >= 1 &&
      samples.length <= MAX_REFERENCE_PHOTOS &&
      samples.every(sample =>
        Array.isArray(sample) &&
        sample.length === 1024 &&
        sample.every(Number.isFinite) &&
        sample.some(number => number !== 0)
      );
  }

  async function getEngine() {
    if (!engineTask) {
      engineTask = (async () => {
        if (!window.Human?.Human) {
          await new Promise((resolve, reject) => {
            const script = document.createElement('script');

            script.src = BASE + 'dist/human.js';
            script.onload = resolve;

            script.onerror = () => {
              script.remove();

              reject(new Error(
                'Không tải được thư viện khuôn mặt. Kiểm tra mạng.'
              ));
            };

            document.head.append(script);
          });
        }

        const human = new window.Human.Human({
          backend: 'webgl',
          modelBasePath: BASE + 'models/',
          cacheSensitivity: 0,
          debug: false,

          filter: {
            enabled: true,
            equalization: true,
            autoBrightness: true,
          },

          face: {
            enabled: true,

            detector: {
              maxDetected: 2,
              rotation: true,
              return: false,
              skipFrames: 0,
              skipTime: 0,
            },

            mesh: { enabled: true },
            iris: { enabled: false },

            description: {
              enabled: true,
              skipFrames: 0,
              skipTime: 0,
            },

            age: { enabled: false },
            gender: { enabled: false },
            emotion: { enabled: false },
            antispoof: { enabled: false },
            liveness: { enabled: false },
          },

          body: { enabled: false },
          hand: { enabled: false },
          object: { enabled: false },
          gesture: { enabled: false },
          segmentation: { enabled: false },
        });

        await human.load();
        return human;
      })().catch(error => {
        engineTask = undefined;
        throw error;
      });
    }

    return engineTask;
  }

  function errorText(error) {
    if (error?.name === 'NotAllowedError') {
      return 'Chưa được cấp quyền camera.';
    }

    if (error?.name === 'NotFoundError') {
      return 'Không tìm thấy webcam.';
    }

    if (error?.name === 'NotReadableError') {
      return 'Webcam đang bận. Hãy đóng ứng dụng dùng camera.';
    }

    return error?.message || 'Chưa xử lý được khuôn mặt.';
  }

  async function sampleFrom(human, source, verifying) {
    const width = source.videoWidth || source.naturalWidth;
    const height = source.videoHeight || source.naturalHeight;

    if (!width || !height) {
      throw new FaceFrameError('Ảnh hoặc camera chưa sẵn sàng.');
    }

    const scale = Math.min(1, 1280 / Math.max(width, height));
    const frame = document.createElement('canvas');

    frame.width = Math.max(1, Math.round(width * scale));
    frame.height = Math.max(1, Math.round(height * scale));

    frame.getContext('2d').drawImage(
      source,
      0,
      0,
      frame.width,
      frame.height
    );

    const task = inference.then(() => human.detect(frame));
    inference = task.catch(() => {});

    const result = await task;

    if (result.face.length !== 1) {
      throw new FaceFrameError(
        result.face.length > 1
          ? 'Ảnh hoặc khung hình chỉ được có một khuôn mặt.'
          : verifying
            ? 'Chưa thấy khuôn mặt. Hãy nhìn thẳng vào webcam.'
            : 'Chưa thấy khuôn mặt trong ảnh. Hãy chọn ảnh thẻ rõ hơn.'
      );
    }

    const face = result.face[0];

    console.info(
      '[AiVie.check] Face quality | stage=' +
      (verifying ? 'verify' : 'enroll') +
      ' | detection=' + face.boxScore +
      ' | size=' + face.box?.[2] + 'x' + face.box?.[3]
    );

    if (
      !Number.isFinite(face.boxScore) ||
      face.boxScore < 0.8 ||
      !face.box ||
      !Number.isFinite(face.box[2]) ||
      !Number.isFinite(face.box[3]) ||
      face.box[2] < 100 ||
      face.box[3] < 100
    ) {
      throw new FaceFrameError(
        verifying
          ? 'Khuôn mặt chưa rõ. Hãy đến gần webcam và tăng ánh sáng.'
          : 'Khuôn mặt trong ảnh quá nhỏ hoặc chưa rõ. Hãy chọn ảnh khác.'
      );
    }

    const sample = Array.from(face.embedding || []);

    if (!validSamples([sample])) {
      throw new Error('Chưa tạo được mẫu khuôn mặt. Hãy thử lại.');
    }

    return sample;
  }

  function waitForResult(task, milliseconds, signal) {
    return new Promise((resolve, reject) => {
      let settled = false;
      let timer;

      function complete(value, failed = false) {
        if (settled) return;

        settled = true;
        clearTimeout(timer);
        signal.removeEventListener('abort', abort);

        if (failed) reject(value);
        else resolve(value);
      }

      function abort() {
        complete(null);
      }

      Promise.resolve(task).then(
        value => complete(value),
        error => complete(error, true)
      );

      if (signal.aborted || milliseconds <= 0) {
        complete(null);
        return;
      }

      signal.addEventListener('abort', abort, { once: true });
      timer = setTimeout(() => complete(null), milliseconds);
    });
  }

  async function verifyFromCamera(
    human,
    video,
    references,
    isCancelled,
    onStatus,
    signal
  ) {
    const deadline = performance.now() + VERIFY_WINDOW_MS;
    const samples = [];
    const scores = [];
    const recentScores = [];

    let lastFrameError;
    let sawMismatch = false;
    let sawInstability = false;

    function resetSamples() {
      samples.length = 0;
      scores.length = 0;
    }

    while (performance.now() < deadline) {
      if (isCancelled()) return false;

      onStatus('Giữ yên khuôn mặt, đang xác minh…');

      let sample;

      try {
        const remaining = deadline - performance.now();

        if (remaining <= 0) break;

        sample = await waitForResult(
          sampleFrom(human, video, true),
          remaining,
          signal
        );
      } catch (error) {
        if (isCancelled()) return false;
        if (!(error instanceof FaceFrameError)) throw error;

        lastFrameError = error;
        resetSamples();
      }

      if (isCancelled()) return false;
      if (performance.now() >= deadline) break;

      if (sample) {
        lastFrameError = undefined;

        const candidates = references.map(reference =>
          human.match.similarity(reference, sample)
        );

        if (!candidates.every(Number.isFinite)) {
          throw new Error(
            'Không tính được điểm so sánh. Hãy thử lại.'
          );
        }

        const score = Math.max(...candidates);
        recentScores.push(score);

        if (recentScores.length > REQUIRED_SAMPLES) {
          recentScores.shift();
        }

        console.info(
          '[AiVie.check] Face comparison | score=' +
          score.toFixed(3) +
          ' | threshold=' + MATCH_THRESHOLD.toFixed(3) +
          ' | matched=' + (score >= MATCH_THRESHOLD)
        );

        if (score < MATCH_THRESHOLD) {
          sawMismatch = true;
          resetSamples();
        } else {
          if (samples.length) {
            const stability = human.match.similarity(
              samples[0],
              sample
            );

            if (!Number.isFinite(stability)) {
              throw new Error(
                'Không tính được điểm ổn định. Hãy thử lại.'
              );
            }

            if (stability < MATCH_THRESHOLD) {
              sawInstability = true;
              resetSamples();
            }
          }

          samples.push(sample);
          scores.push(score);

          if (samples.length === REQUIRED_SAMPLES) {
            console.info(
              '[AiVie.check] Face verified | scores=' +
              scores.map(value => value.toFixed(3)).join(', ')
            );

            return true;
          }
        }
      }

      const remaining = deadline - performance.now();

      if (remaining <= 0) break;

      await waitForResult(
        new Promise(() => {}),
        Math.min(SAMPLE_INTERVAL_MS, remaining),
        signal
      );
    }

    if (isCancelled()) return false;

    console.info(
      '[AiVie.check] Face verification stopped | recent scores=' +
      recentScores.map(value => value.toFixed(3)).join(', ')
    );

    if (sawMismatch) {
      throw new Error('Khuôn mặt chưa khớp với tài khoản này.');
    }

    if (lastFrameError) throw lastFrameError;

    if (sawInstability || samples.length) {
      throw new Error(
        'Khuôn mặt chưa ổn định.\n' +
        'Hãy nhìn thẳng, giữ yên và thử lại.'
      );
    }

    throw new Error('Chưa xử lý được khuôn mặt. Hãy thử lại.');
  }

  function validPreview(photo) {
    return photo &&
      typeof photo.name === 'string' &&
      photo.name.length > 0 &&
      photo.name.length <= 255 &&
      typeof photo.key === 'string' &&
      photo.key.length <= 512 &&
      typeof photo.dataUrl === 'string' &&
      photo.dataUrl.length <= MAX_PREVIEW_CHARS &&
      /^data:image\/jpeg;base64,[A-Za-z0-9+/]+={0,2}$/.test(
        photo.dataUrl
      );
  }

  function previewFrom(image) {
    for (const [edge, quality] of [
      [320, 0.7],
      [240, 0.65],
      [160, 0.6],
    ]) {
      const scale = Math.min(
        1,
        edge / Math.max(image.naturalWidth, image.naturalHeight)
      );

      const canvas = document.createElement('canvas');

      canvas.width = Math.max(
        1,
        Math.round(image.naturalWidth * scale)
      );

      canvas.height = Math.max(
        1,
        Math.round(image.naturalHeight * scale)
      );

      const context = canvas.getContext('2d');

      context.fillStyle = 'white';
      context.fillRect(0, 0, canvas.width, canvas.height);
      context.drawImage(image, 0, 0, canvas.width, canvas.height);

      const dataUrl = canvas.toDataURL('image/jpeg', quality);

      if (validPreview({name: 'Ảnh', key: '', dataUrl})) {
        return dataUrl;
      }
    }

    throw new Error(
      'Chưa tạo được ảnh xem trước. Hãy chọn ảnh khác.'
    );
  }

  function readExistingProfile(profile) {
    if (!profile) {
      return {photos: [], needsPhotos: false};
    }

    if (profile.model !== MODEL || !validSamples(profile.samples)) {
      throw new Error('Bộ mẫu khuôn mặt đã lưu không hợp lệ.');
    }

    if (
      profile.preprocessing !== PREPROCESSING ||
      !Array.isArray(profile.photos) ||
      profile.photos.length === 0
    ) {
      return {photos: [], needsPhotos: true};
    }

    if (
      profile.photos.length !== profile.samples.length ||
      !profile.photos.every(validPreview)
    ) {
      throw new Error(
        'Dữ liệu ảnh xem trước đã lưu không hợp lệ.'
      );
    }

    return {
      needsPhotos: false,
      photos: profile.photos.map((photo, index) => ({
        ...photo,
        sample: profile.samples[index],
      })),
    };
  }

  function prepareDialogStyle() {
    if (document.getElementById('aivy-face-style')) return;
  
    const font = document.createElement('link');
    font.rel = 'stylesheet';
    font.href =
      'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap';
  
    const style = document.createElement('style');
    style.id = 'aivy-face-style';
  
    style.textContent = `
      .aivy-face-dialog {
        --aivie-background: #f7f8fa;
        --aivie-surface: #ffffff;
        --aivie-text: #1f2937;
        --aivie-muted: #6b7280;
        --aivie-border: #e5e7eb;
        --aivie-primary: #2563eb;
        --aivie-hover: #eff6ff;
        --aivie-action: #2563eb;
        --aivie-action-hover: #1d4ed8;
        --aivie-error: #b91c1c;
        color-scheme: light;
      }
  
      html[data-aivie-theme="dark"] .aivy-face-dialog {
        --aivie-background: #111827;
        --aivie-surface: #1b2433;
        --aivie-text: #f3f4f6;
        --aivie-muted: #b5bfce;
        --aivie-border: #354154;
        --aivie-primary: #93b4ff;
        --aivie-hover: #263b61;
        --aivie-error: #fca5a5;
        color-scheme: dark;
      }
  
      .aivy-face-dialog {
        box-sizing: border-box;
        width: min(640px, calc(100vw - 32px));
        max-height: calc(100vh - 32px);
        max-height: calc(100dvh - 32px);
        margin: auto;
        padding: 0;
        overflow: hidden;
        border: 1px solid var(--aivie-border);
        border-radius: 12px;
        background: var(--aivie-background);
        color: var(--aivie-text);
        font: 14px/1.5 Inter, Arial, sans-serif;
        box-shadow: 0 16px 48px #0002;
      }
  
      .aivy-face-dialog[open] {
        display: flex;
        flex-direction: column;
      }
  
      .aivy-face-dialog [hidden] {
        display: none !important;
      }
  
      .aivy-face-dialog::backdrop {
        background: #1f293733;
      }
  
      .aivy-face-header {
        flex: 0 0 auto;
        padding: 20px 24px 12px;
      }
  
      .aivy-face-header h2 {
        margin: 0;
        font-size: 20px;
        font-weight: 600;
      }
  
      .aivy-face-header [data-name] {
        margin: 6px 0 0;
        color: var(--aivie-muted);
        overflow-wrap: anywhere;
      }
  
      .aivy-face-body {
        flex: 1 1 auto;
        min-height: 0;
        overflow-y: auto;
        overscroll-behavior: contain;
        padding: 0 24px 16px;
      }
  
      .aivy-face-dialog video {
        display: block;
        width: 100%;
        height: clamp(120px, 45vh, 360px);
        height: clamp(120px, 45dvh, 360px);
        object-fit: contain;
        border-radius: 12px;
        background: #111827;
        transform: scaleX(-1);
      }
  
      .aivy-face-dialog [data-status] {
        margin: 12px 0 0;
        min-height: 42px;
        line-height: 1.5;
        color: var(--aivie-muted);
        white-space: pre-line;
      }
  
      .aivy-face-footer {
        flex: 0 0 auto;
        display: flex;
        justify-content: flex-end;
        flex-wrap: wrap;
        gap: 12px;
        padding: 16px 24px;
        border-top: 1px solid var(--aivie-border);
        background: var(--aivie-background);
      }
  
      .aivy-face-dialog button {
        font: inherit;
        font-weight: 500;
        cursor: pointer;
        border-radius: 12px;
        padding: 12px 16px;
        border: 1px solid var(--aivie-border);
        background: var(--aivie-surface);
        color: var(--aivie-primary);
      }
  
      .aivy-face-dialog button:disabled {
        opacity: .5;
        cursor: default;
      }
  
      .aivy-face-dialog button:hover:not(:disabled) {
        background: var(--aivie-hover);
      }
  
      .aivy-face-dialog button:focus-visible {
        outline: 2px solid var(--aivie-primary);
        outline-offset: 2px;
      }
  
      .aivy-face-dialog [data-capture] {
        background: var(--aivie-action);
        color: white;
        border-color: var(--aivie-primary);
      }
  
      .aivy-face-dialog [data-capture]:hover:not(:disabled) {
        background: var(--aivie-action-hover);
      }
  
      @media (max-height: 500px) {
        .aivy-face-header {
          padding: 12px 16px 8px;
        }
  
        .aivy-face-body {
          padding: 0 16px 12px;
        }
  
        .aivy-face-footer {
          padding: 12px 16px;
        }
  
        .aivy-face-dialog video {
          height: clamp(80px, 35vh, 180px);
          height: clamp(80px, 35dvh, 180px);
        }
      }
    `;
  
    document.head.append(font, style);
  }

  function createPhotoPicker({
    fileInput,
    addButton,
    previews,
    count,
    status,
    isClosed,
    onReadyChange,
    initialPhotos,
    needsPhotos,
  }) {
    const photos = [];
    const pendingPhotos = [];

    let loading = false;
    let busy = false;
    let disposed = false;
    let readingController;

    function refresh() {
      const locked = busy || loading || disposed;

      fileInput.disabled = locked;
      addButton.disabled =
        locked || photos.length >= MAX_REFERENCE_PHOTOS;

      addButton.style.opacity = addButton.disabled ? '.5' : '1';

      count.textContent =
        'Đã chọn ' + photos.length + '/' +
        MAX_REFERENCE_PHOTOS + ' ảnh';

      previews.hidden = photos.length === 0;
      previews.style.display = photos.length ? 'grid' : 'none';

      for (const photo of photos) {
        photo.removeButton.disabled = locked;
      }

      onReadyChange(!locked);
    }

    function selectionMessage() {
      status.textContent = photos.length
        ? 'Có thể thêm ảnh hoặc dùng dấu × để bỏ ảnh. ' +
          'Bấm “Lưu” để lưu thay đổi.'
        : needsPhotos
          ? 'Tài khoản đã có mẫu nhận diện nhưng chưa có ảnh xem trước. ' +
            'Chọn lại ảnh để cập nhật, hoặc bấm “Lưu” để gỡ mẫu khuôn mặt.'
          : 'Danh sách ảnh đang trống. ' +
            'Bấm “Lưu” để tài khoản ở trạng thái chưa đăng ký khuôn mặt.';
    }

    function releasePhoto(photo) {
      photo.image.onload = null;
      photo.image.onerror = null;
      photo.image.removeAttribute('src');

      if (photo.url) URL.revokeObjectURL(photo.url);

      photo.card.remove();
    }

    function createPhoto(file, saved) {
      const card = document.createElement('div');

      card.style.cssText =
      'position:relative;min-width:0;padding:8px;' +
      'border:1px solid var(--aivie-border);' +
      'border-radius:12px;background:var(--aivie-surface)';

      const image = document.createElement('img');

      image.alt = file.name || 'Ảnh đăng ký đã chọn';

      image.style.cssText =
      'display:block;width:100%;height:160px;object-fit:contain;' +
      'border-radius:8px;background:var(--aivie-background)';

      const label = document.createElement('div');

      label.textContent = image.alt;
      label.title = image.alt;

      label.style.cssText =
        'margin-top:8px;font-size:12px;white-space:nowrap;' +
        'overflow:hidden;text-overflow:ellipsis';

      const removeButton = document.createElement('button');

      removeButton.type = 'button';
      removeButton.textContent = '×';
      removeButton.title = 'Bỏ ảnh này';
      removeButton.setAttribute('aria-label', 'Bỏ ảnh ' + image.alt);

      removeButton.style.cssText =
      'position:absolute;top:4px;right:4px;width:30px;height:30px;' +
      'border:1px solid var(--aivie-border);' +
      'border-radius:50%;background:var(--aivie-surface);' +
      'color:var(--aivie-error);font-size:24px;line-height:1;' +
      'cursor:pointer;padding:0;box-shadow:0 2px 6px #0002';

      const photo = {
        image,
        card,
        removeButton,
        name: image.alt,
        key: saved
          ? saved.key
          : [file.name, file.size, file.lastModified].join('|'),
        sample: saved?.sample || null,
        dataUrl: saved?.dataUrl || null,
        url: null,
      };

      removeButton.onclick = () => {
        if (disposed || isClosed() || busy || loading) return;

        const index = photos.indexOf(photo);

        if (index < 0) return;

        photos.splice(index, 1);
        releasePhoto(photo);
        refresh();
        selectionMessage();
      };

      card.append(image, removeButton, label);

      return photo;
    }

    async function readPhoto(photo, file, signal) {
      const task = new Promise((resolve, reject) => {
        photo.image.onload = () => {
          if (
            !photo.image.naturalWidth ||
            !photo.image.naturalHeight
          ) {
            reject(new Error(
              'Không đọc được ảnh: ' + photo.name
            ));
          } else {
            resolve(true);
          }
        };

        photo.image.onerror = () => {
          reject(new Error('Ảnh bị lỗi: ' + photo.name));
        };

        photo.url = URL.createObjectURL(file);
        photo.image.src = photo.url;
      });

      const ready = await waitForResult(task, 15000, signal);

      if (!ready) {
        throw new Error('Đọc ảnh quá lâu: ' + photo.name);
      }
    }

    addButton.onclick = () => {
      if (disposed || isClosed() || addButton.disabled) return;

      fileInput.value = '';
      fileInput.click();
    };

    fileInput.addEventListener('cancel', event => {
      event.stopPropagation();
    });

    fileInput.onchange = async () => {
      if (disposed || isClosed() || busy || loading) return;

      const files = Array.from(fileInput.files || []);

      fileInput.value = '';

      if (!files.length) return;

      if (files.some(file =>
        !['image/jpeg', 'image/png', 'image/webp'].includes(file.type) ||
        file.size === 0 ||
        file.size > 5 * 1024 * 1024
      )) {
        status.textContent =
          'Mỗi ảnh cần là JPG, PNG hoặc WebP, không quá 5 MB.';

        return;
      }

      const keys = new Set(photos.map(photo => photo.key));

      const additions = files.filter(file => {
        const key = [
          file.name,
          file.size,
          file.lastModified,
        ].join('|');

        if (keys.has(key)) return false;

        keys.add(key);
        return true;
      });

      if (!additions.length) {
        status.textContent = 'Ảnh này đã có trong danh sách.';
        return;
      }

      if (photos.length + additions.length > MAX_REFERENCE_PHOTOS) {
        status.textContent =
          'Mỗi tài khoản đăng ký tối đa ' + MAX_REFERENCE_PHOTOS +
          ' ảnh. Hãy bỏ bớt ảnh bằng dấu × trước khi thêm.';

        return;
      }

      loading = true;
      readingController = new AbortController();

      refresh();
      status.textContent = 'Đang đọc ảnh mới…';

      try {
        const reads = additions.map(file => {
          const photo = createPhoto(file);

          pendingPhotos.push(photo);

          return readPhoto(photo, file, readingController.signal);
        });

        await Promise.all(reads);

        if (disposed || isClosed()) return;

        for (const photo of pendingPhotos) {
          photos.push(photo);
          previews.append(photo.card);
        }

        pendingPhotos.length = 0;
        selectionMessage();
      } catch (error) {
        if (!disposed && !isClosed()) {
          status.textContent = errorText(error);
        }
      } finally {
        readingController.abort();
        readingController = undefined;

        for (const photo of pendingPhotos) {
          releasePhoto(photo);
        }

        pendingPhotos.length = 0;
        loading = false;

        if (!disposed && !isClosed()) refresh();
      }
    };

    for (const saved of initialPhotos) {
      const photo = createPhoto({name: saved.name}, saved);

      photo.image.src = saved.dataUrl;
      photos.push(photo);
      previews.append(photo.card);
    }

    refresh();
    selectionMessage();

    return {
      get ready() {
        return !disposed && !loading;
      },

      get items() {
        return photos.slice();
      },

      setBusy(value) {
        busy = value;
        refresh();
      },

      dispose() {
        if (disposed) return;

        disposed = true;
        readingController?.abort();

        for (const photo of [...photos, ...pendingPhotos]) {
          releasePhoto(photo);
        }

        photos.length = 0;
        pendingPhotos.length = 0;

        previews.replaceChildren();
      },
    };
  }

  window.aivyFaceRun = async (
    name,
    referenceText,
    editText = '{}'
  ) => {
    if (active) {
      return JSON.stringify({
        status: 'error',
        message: 'Đang xử lý khuôn mặt. Hãy đóng cửa sổ hiện tại.',
      });
    }

    let references;
    let existing;

    try {
      references = JSON.parse(referenceText);

      const options = JSON.parse(editText);

      if (
        !options ||
        (
          options.apiVersion != null &&
          options.apiVersion !== API_VERSION
        )
      ) {
        throw new Error();
      }

      if (
        !Array.isArray(references) ||
        (references.length > 0 && !validSamples(references))
      ) {
        throw new Error();
      }

      existing = references.length
        ? {photos: [], needsPhotos: false}
        : readExistingProfile(options.profile);
    } catch (_) {
      return JSON.stringify({
        status: 'error',
        message: 'Mẫu khuôn mặt không hợp lệ.',
      });
    }

    const verifying = references.length > 0;

    if (
      verifying &&
      (!window.isSecureContext ||
        !navigator.mediaDevices?.getUserMedia)
    ) {
      return JSON.stringify({
        status: 'error',
        message: 'Hãy mở app bằng HTTPS hoặc localhost để dùng webcam.',
      });
    }

    prepareDialogStyle();
    active = true;

    return new Promise(resolve => {
      let done = false;

      const stopped = new AbortController();

      let stream;
      let human;
      let timer;
      let processing = false;

      const previousFocus = document.activeElement;
      const dialog = document.createElement('dialog');

      dialog.className = 'aivy-face-dialog';

      dialog.innerHTML = `
      <header class="aivy-face-header">
        <h2></h2>
        <p data-name></p>
      </header>
    
      <div class="aivy-face-body">
        <div data-photo hidden>
          <p style="margin:0 0 12px;line-height:1.5">
            Chọn 1–${MAX_REFERENCE_PHOTOS} ảnh rõ của cùng một người,
            đúng với tài khoản này. Có thể thêm ảnh từng lần.
            JPG, PNG hoặc WebP; mỗi ảnh tối đa 5 MB.
          </p>
    
          <input data-file type="file" multiple hidden
                 accept="image/jpeg,image/png,image/webp">
    
          <div style="display:flex;align-items:center;gap:12px;
                      flex-wrap:wrap;margin-bottom:12px">
            <button data-add-photo type="button"
                    style="border-color:var(--aivie-primary)">
              Thêm ảnh
            </button>
    
            <span data-photo-count aria-live="polite"
                  style="font-size:14px;color:var(--aivie-muted)">
            </span>
          </div>
    
          <div data-previews hidden
               style="grid-template-columns:repeat(auto-fit,minmax(140px,1fr));
                      gap:12px">
          </div>
        </div>
    
        <video autoplay muted playsinline hidden></video>
    
        <p data-status role="status"></p>
      </div>
    
      <footer class="aivy-face-footer">
        <button data-cancel type="button">Hủy</button>
        <button data-capture type="button" disabled></button>
      </footer>
    `;

      const video = dialog.querySelector('video');
      const photo = dialog.querySelector('[data-photo]');
      const fileInput = dialog.querySelector('[data-file]');
      const previews = dialog.querySelector('[data-previews]');
      const status = dialog.querySelector('[data-status]');
      const capture = dialog.querySelector('[data-capture]');

      status.style.whiteSpace = 'pre-line';

      dialog.querySelector('h2').textContent = verifying
        ? 'Xác minh khuôn mặt'
        : 'Đăng ký bằng ảnh';

      dialog.querySelector('[data-name]').textContent = name;

      capture.textContent = verifying
        ? 'Xác minh'
        : 'Lưu khuôn mặt';

      video.hidden = !verifying;
      photo.hidden = verifying;

      status.textContent = verifying
        ? 'Đang chuẩn bị webcam và bộ xử lý…'
        : 'Bấm “Thêm ảnh” để chọn ảnh từ máy.';

      function enableCapture(enabled) {
        capture.disabled = !enabled;
        capture.style.opacity = enabled ? '1' : '.5';
      }

      const photoPicker = verifying ? null : createPhotoPicker({
        fileInput,
        addButton: dialog.querySelector('[data-add-photo]'),
        previews,
        count: dialog.querySelector('[data-photo-count]'),
        status,
        isClosed: () => done,
        onReadyChange: enableCapture,
        initialPhotos: existing.photos,
        needsPhotos: existing.needsPhotos,
      });

      function finish(result) {
        if (done) return;

        done = true;
        stopped.abort();

        clearTimeout(timer);
        stream?.getTracks().forEach(track => track.stop());

        video.srcObject = null;
        photoPicker?.dispose();

        dialog.remove();
        window.removeEventListener('pagehide', cancel);

        active = false;
        previousFocus?.focus?.();

        resolve(JSON.stringify(result));
      }

      function cancel() {
        finish({status: 'cancelled'});
      }

      dialog.querySelector('[data-cancel]').onclick = cancel;

      dialog.addEventListener('cancel', event => {
        if (event.target !== dialog) return;

        event.preventDefault();
        cancel();
      });

      window.addEventListener('pagehide', cancel);

      document.body.append(dialog);
      dialog.showModal();

      if (verifying) {
        timer = setTimeout(() => {
          finish({
            status: 'error',
            message: 'Webcam hoặc bộ xử lý chờ quá lâu. Hãy thử lại.',
          });
        }, 90000);

        const cameraTask = navigator.mediaDevices.getUserMedia({
          audio: false,

          video: {
            width: {ideal: 1280},
            height: {ideal: 720},
          },
        }).then(value => {
          if (done) {
            value.getTracks().forEach(track => track.stop());
            return;
          }

          stream = value;
          video.srcObject = value;

          return video.play();
        });

        Promise.all([getEngine(), cameraTask])
          .then(([engine]) => {
            if (done) return;

            human = engine;
            clearTimeout(timer);

            status.textContent =
              'Chỉ một người trong khung hình. ' +
              'Nhìn thẳng, đủ sáng rồi bấm Xác minh.';

            enableCapture(true);
          })
          .catch(error => {
            finish({
              status: 'error',
              message: errorText(error),
            });
          });
      }

      capture.onclick = async () => {
        if (capture.disabled || done || processing) return;

        processing = true;
        photoPicker?.setBusy(true);
        enableCapture(false);

        const selectedPhotos = photoPicker?.items || [];

        const processingLimit = (human ? 45000 : 90000) +
          (
            verifying
              ? 0
              : selectedPhotos.filter(photo => !photo.sample).length * 15000
          );

        timer = setTimeout(() => {
          finish({
            status: 'error',
            message: 'Xử lý khuôn mặt quá lâu. Hãy thử lại.',
          });
        }, processingLimit);

        try {
          if (!verifying && !photoPicker.ready) {
            throw new Error('Ảnh đang được đọc. Vui lòng chờ.');
          }
          
          if (!verifying && selectedPhotos.length === 0) {
            finish({
              status: 'ok',
              apiVersion: API_VERSION,
              model: MODEL,
              preprocessing: PREPROCESSING,
              cleared: true,
            });
            return;
          }

          status.textContent = 'Đang chuẩn bị bộ xử lý khuôn mặt…';

          if (
            verifying ||
            selectedPhotos.some(photo => !photo.sample)
          ) {
            human = human || await getEngine();
          }

          if (done) return;

          if (!verifying) {
            status.textContent = 'Đang kiểm tra khuôn mặt trong ảnh…';

            const samples = [];
            const photos = [];

            for (const photo of selectedPhotos) {
              if (done) return;

              try {
                const sample = photo.sample || await sampleFrom(
                  human,
                  photo.image,
                  false
                );

                const dataUrl =
                  photo.dataUrl || previewFrom(photo.image);

                if (done) return;

                samples.push(sample);

                photos.push({
                  name: photo.name,
                  key: photo.key,
                  dataUrl,
                });
              } catch (error) {
                throw new Error(
                  'Ảnh "' + photo.name + '": ' +
                  errorText(error)
                );
              }
            }

            if (!validSamples(samples)) {
              throw new Error(
                'Chưa tạo được bộ mẫu khuôn mặt hợp lệ.'
              );
            }

            if (!done) {
              finish({
                status: 'ok',
                apiVersion: API_VERSION,
                model: MODEL,
                preprocessing: PREPROCESSING,
                samples,
                photos,
              });
            }

            return;
          }

          const matched = await verifyFromCamera(
            human,
            video,
            references,
            () => done,
            message => {
              if (!done) status.textContent = message;
            },
            stopped.signal
          );

          if (done) return;

          if (!matched) {
            throw new Error(
              'Khuôn mặt chưa khớp với tài khoản này.'
            );
          }

          finish({
            status: 'ok',
            apiVersion: API_VERSION,
            matched: true,
            preprocessing: PREPROCESSING,
          });
        } catch (error) {
          if (done) return;

          clearTimeout(timer);

          status.textContent = errorText(error);
          processing = false;

          photoPicker?.setBusy(false);
          enableCapture(verifying || photoPicker.ready);
        }
      };
    });
  };
})();