import bcrypt

class Hash:
    @staticmethod
    def bcrypt(password: str):
        # bcrypt requires bytes, so encode first
        pwd_bytes = password.encode('utf-8')
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(pwd_bytes, salt)
        return hashed.decode('utf-8') # Store as string
        
    @staticmethod
    def verify(plain_password, hashed_password):
        pwd_bytes = plain_password.encode('utf-8')
        # hashed_password might be string from DB, encode to bytes
        hash_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(pwd_bytes, hash_bytes)