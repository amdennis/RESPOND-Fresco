import dotenv from 'dotenv';
dotenv.config();

import { execSync } from 'child_process';

// Use npx to ensure local prisma CLI is invoked
try {
  console.log('🔧 Running Prisma generate...');
  execSync('npx prisma generate', { stdio: 'inherit' });
  console.log('✅ Prisma generate completed!');
} catch (err) {
  console.error('❌ Prisma generate failed:', err);
  process.exit(1);
}

