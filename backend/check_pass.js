import bcrypt from 'bcryptjs';

const hash = '$2b$10$YBva6GD8BZA6CJBg9dlK.OQCGQHsLQdVtt0M1TqdCSOMF9HAwtSFS';
const pass = 'aashu@123';
const pass2 = '123456';
const pass3 = 'Security@123';

console.log('123456:', bcrypt.compareSync(pass2, hash));
console.log('aashu@123:', bcrypt.compareSync(pass, hash));
console.log('Security@123:', bcrypt.compareSync(pass3, hash));
