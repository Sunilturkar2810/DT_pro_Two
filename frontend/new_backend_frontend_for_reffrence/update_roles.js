const fs = require('fs');
const path = require('path');

const walkSync = (dir, filelist = []) => {
  try {
    const files = fs.readdirSync(dir);
    for (const file of files) {
      const dirFile = path.join(dir, file);
      if (fs.statSync(dirFile).isDirectory()) {
        if (!['node_modules', '.git', 'dist', 'build', '.next', 'coverage'].includes(file)) {
          filelist = walkSync(dirFile, filelist);
        }
      } else {
        if (['.js', '.jsx', '.ts', '.tsx', '.md'].includes(path.extname(dirFile))) {
          filelist.push(dirFile);
        }
      }
    }
  } catch (err) {
    console.error("Error reading dir", dir, err);
  }
  return filelist;
};

const rootDir = __dirname;
let files = [];
if (fs.existsSync(path.join(rootDir, 'Frontend'))) {
    files = files.concat(walkSync(path.join(rootDir, 'Frontend')));
}
if (fs.existsSync(path.join(rootDir, 'backend'))) {
    files = files.concat(walkSync(path.join(rootDir, 'backend')));
}

let changedFiles = 0;

files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let originalContent = content;
  
  // Replace role strings in quotes
  content = content.replace(/(['"`])Admin\1/g, "$1ADMIN$1");
  content = content.replace(/(['"`])admin\1/g, "$1ADMIN$1");
  content = content.replace(/(['"`])SuperAdmin\1/g, "$1SUPERADMIN$1");
  content = content.replace(/(['"`])Superadmin\1/g, "$1SUPERADMIN$1");
  content = content.replace(/(['"`])superadmin\1/g, "$1SUPERADMIN$1");
  content = content.replace(/(['"`])Manager\1/g, "$1MANAGER$1");
  content = content.replace(/(['"`])manager\1/g, "$1MANAGER$1");
  content = content.replace(/(['"`])Team Member\1/g, "$1TEAM MEMBER$1");
  content = content.replace(/(['"`])Team member\1/g, "$1TEAM MEMBER$1");
  content = content.replace(/(['"`])team member\1/g, "$1TEAM MEMBER$1");

  // Visible text in JSX
  content = content.replace(/>\s*Admin\s*</g, ">ADMIN<");
  content = content.replace(/>\s*SuperAdmin\s*</g, ">SUPERADMIN<");
  content = content.replace(/>\s*Superadmin\s*</g, ">SUPERADMIN<");
  content = content.replace(/>\s*Manager\s*</g, ">MANAGER<");
  content = content.replace(/>\s*Team Member\s*</g, ">TEAM MEMBER<");
  content = content.replace(/>\s*Team member\s*</g, ">TEAM MEMBER<");

  // Fix specific edge case: ['Admin', 'SuperAdmin']
  content = content.replace(/\['Admin', 'SuperAdmin'\]/g, "['ADMIN', 'SUPERADMIN']");

  if (content !== originalContent) {
    fs.writeFileSync(file, content, 'utf8');
    console.log('Updated:', file);
    changedFiles++;
  }
});

console.log(`Finished updating ${changedFiles} files.`);
