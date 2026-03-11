// Test S3 upload
import { uploadToS3 } from './src/utils/s3.js';

try {
    process.stdout.write('Testing S3 upload...\n');
    const testBuffer = Buffer.from('Hello test file ' + Date.now());
    const url = await uploadToS3(testBuffer, 'test.txt', 'test-uploads');
    process.stdout.write(`✅ S3 Upload SUCCESS: ${url}\n`);
} catch(e) {
    process.stdout.write(`❌ S3 Upload FAILED: ${e.message}\n`);
    if (e.Code) process.stdout.write(`Error Code: ${e.Code}\n`);
}
process.exit(0);
