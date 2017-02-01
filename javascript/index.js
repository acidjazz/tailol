var Tail, blessed, boxen, file, files, fs, index, j, len, log, log_file, ref, screen, shift, shiftBox, shiftIndex, shiftValue, tails, util;

fs = require('fs');

files = [];

if (process.argv.length < 3) {
  console.log('Usage: tailol file [file file...]');
  process.exit(0);
}

ref = process.argv;
for (index = j = 0, len = ref.length; j < len; index = ++j) {
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

blessed = require('blessed');

screen = blessed.screen({
  smartCSR: true
});

Tail = require('tail').Tail;

util = require('util');

log_file = fs.createWriteStream('./debug.log', {
  flags: 'w'
});

log = function(d) {
  return log_file.write(util.format(d) + "\n");
};

screen.title = "tailoling " + files.length + " files";

boxen = [];

tails = [];

shift = 0;

shiftIndex = false;

shiftValue = false;

shiftBox = false;

files.forEach(function(file, i) {
  var filename;
  filename = file.replace(/^.*[\\\/]/, '');
  boxen.push({
    index: i,
    current: false,
    list: blessed.List({
      top: (100 / files.length * i) + '%',
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
          fg: 'grey'
        },
        focus: {
          label: {
            fg: 'white'
          }
        },
        border: {
          fg: 'green'
        },
        selected: {
          fg: 'blue'
        }
      }
    })
  });
  boxen[i].list.on('focus', function() {
    return boxen[i].list.setFront();
  });
  boxen[i].list.key(['up', 'down'], function() {
    if (shiftIndex !== false && boxen[i].list.selected !== shiftIndex) {
      boxen[i].list.setItem(shiftIndex, shiftValue);
      screen.render();
      shift = 0;
      shiftBox = false;
      shiftValue = false;
      return shiftIndex = false;
    }
  });
  boxen[i].list.key('$', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift = boxen[i].list.value.length - boxen[i].list.width + 3;
      shiftIndex = boxen[i].list.selected;
      if (shiftValue === false) {
        shiftValue = boxen[i].list.value;
      }
      shiftBox = i;
      boxen[i].list.setItem(boxen[i].list.selected, shiftValue.substring(shift));
      return screen.render();
    }
  });
  boxen[i].list.key('^', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift = 0;
      shiftIndex = boxen[i].list.selected;
      if (shiftValue === false) {
        shiftValue = boxen[i].list.value;
      }
      shiftBox = i;
      boxen[i].list.setItem(boxen[i].list.selected, shiftValue.substring(shift));
      return screen.render();
    }
  });
  boxen[i].list.key('right', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift++;
      shiftIndex = boxen[i].list.selected;
      if (shiftValue === false) {
        shiftValue = boxen[i].list.value;
      }
      shiftBox = i;
      boxen[i].list.setItem(boxen[i].list.selected, shiftValue.substring(shift));
      return screen.render();
    }
  });
  boxen[i].list.key('space', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift += 10;
      shiftIndex = boxen[i].list.selected;
      if (shiftValue === false) {
        shiftValue = boxen[i].list.value;
      }
      shiftBox = i;
      boxen[i].list.setItem(boxen[i].list.selected, shiftValue.substring(shift));
      return screen.render();
    }
  });
  boxen[i].list.key('left', function() {
    if (shift > 0) {
      shift--;
      boxen[i].list.setItem(boxen[i].list.selected, shiftValue.substring(shift));
      return screen.render();
    }
  });
  screen.append(boxen[i].list);
  tails.push(new Tail(file));
  return tails[i].on('line', function(data) {
    boxen[i].list.add(data);
    boxen[i].list.scrollTo(boxen[i].list.getScrollHeight());
    boxen[i].list.select(boxen[i].list.items.length - 1);
    boxen[i].current = boxen[i].list.items.length - 1;
    return screen.render();
  });
});

screen.key(['escape', 'q', 'C-c'], function(ch, key) {
  return process.exit(0);
});

screen.key(['tab'], function(ch, key) {
  if (shiftBox !== false) {
    boxen[shiftBox].list.setItem(shiftIndex, shiftValue);
    screen.render();
    shift = 0;
    shiftValue = false;
    shiftIndex = false;
    shiftBox = false;
  }
  screen.focusNext();
  return screen.render();
});

screen.key(['S-tab'], function(ch, key) {
  if (shiftBox !== false) {
    boxen[shiftBox].list.setItem(shiftIndex, shiftValue);
    screen.render();
    shift = 0;
    shiftValue = false;
    shiftBox = false;
  }
  screen.focusPrevious();
  return screen.render();
});

boxen[0].list.focus();

boxen[0].list.setFront();

screen.render();
