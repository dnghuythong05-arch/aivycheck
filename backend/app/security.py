from pwdlib import PasswordHash
from pwdlib.exceptions import UnknownHashError


password_hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    if not password:
        raise ValueError("Hãy nhập mật khẩu.")

    if len(password) > 128:
        raise ValueError("Mật khẩu không được quá 128 ký tự.")

    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    if not 1 <= len(password) <= 128:
        return False

    try:
        return password_hasher.verify(password, password_hash)
    except UnknownHashError:
        return False