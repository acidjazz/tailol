var Tail, blessed, boxen, file, files, fs, i, index, len, ref, screen, tails;

fs = require('fs');

files = [];

if (process.argv.length < 3) {
  console.log('Usage: tailol files [file file...]');
  process.exit(0);
}

ref = process.argv;
for (index = i = 0, len = ref.length; i < len; index = ++i) {
  file = ref[index];
  if (index < 2) {
    continue;
  }
  if (!fs.existsSync(file)) {
    console.log("File: \"" + file + "\" cannot be found");
    process.exit(0);
  }
  files.push(file);
}

console.log(files);

blessed = require('blessed');

screen = blessed.screen({
  smartCSR: true
});

Tail = require('tail').Tail;

screen.title = "tailoling " + files.length + " files";

boxen = [];

tails = [];

files.forEach(function(file, index) {
  var filename;
  filename = file.replace(/^.*[\\\/]/, '');
  boxen.push(blessed.List({
    top: (100 / files.length * index) + '%',
    height: 100 / files.length + '%',
    label: filename,
    border: {
      type: 'line'
    },
    scrollable: true,
    scrollbar: {
      style: {
        bg: 'blue'
      }
    },
    alwaysScroll: true,
    keys: true,
    vi: true,
    interactive: true,
    style: {
      label: {
        fg: 'green'
      },
      border: {
        fg: 'blue'
      },
      selected: {
        fg: 'blue'
      }
    }
  }));
  screen.append(boxen[index]);
  tails.push(new Tail(file));
  return tails[index].on('line', function(data) {
    boxen[index].add(data);
    boxen[index].scrollTo(boxen[index].getScrollHeight());
    boxen[index].select(boxen[index].items.length - 1);
    return screen.render();
  });
});

screen.key(['escape', 'q', 'C-c'], function(ch, key) {
  return process.exit(0);
});

screen.key(['tab'], function(ch, key) {
  return screen.focusNext();
});

screen.key(['S-tab'], function(ch, key) {
  return screen.focusPrevious();
});

screen.render();
