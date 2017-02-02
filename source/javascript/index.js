var Tail, blessed, boxen, file, files, fs, index, j, len, modal, ref, screen, shift, tails;

fs = require('fs');

files = [];

if (process.argv.length < 3) {
  console.log('Usage: tailol file [file file...]');
  process.exit(0);
}

if (process.argv[2] === '-v') {
  console.log(require('../package.json').version);
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


/*
util = require 'util'
log_file = fs.createWriteStream('./debug.log', {flags : 'w'})
log = (d) ->
  log_file.write util.format(d) + "\n"
 */

screen.title = "tailoling " + files.length + " files";

boxen = [];

tails = [];

modal = false;

shift = {
  cursor: 0,
  index: false,
  value: false,
  box: false,
  reset: function() {
    this.cursor = 0;
    this.index = false;
    this.value = false;
    return this.box = false;
  }
};

files.forEach(function(file, i) {
  var filename;
  filename = file.replace(/^.*[\\\/]/, '');
  boxen.push({
    index: i,
    current: false,
    shift: function(i) {
      shift.index = this.list.selected;
      if (shift.value === false) {
        shift.value = this.list.value;
      }
      shift.box = i;
      return this.list.setItem(this.list.selected, shift.value.substring(shift.cursor));
    },
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
  boxen[i].list.key('m', function() {
    if (boxen[i].list.height === screen.height) {
      boxen[i].list.top = (100 / files.length * i) + '%';
      boxen[i].list.height = 100 / files.length + '%';
      boxen[i].list.scrollTo(boxen[i].list.getScrollHeight());
    } else {
      boxen[i].list.top = '0';
      boxen[i].list.height = '100%';
      boxen[i].list.scrollTo(boxen[i].list.getScrollHeight());
    }
    return screen.render();
  });
  boxen[i].list.on('select', function(selected) {
    if (shift.index !== false) {
      boxen[i].list.setItem(shift.index, shift.value);
      screen.render();
      shift.reset();
    }
    modal = blessed.box({
      top: 'center',
      left: '10%',
      width: '80%',
      height: '50%',
      label: selected.content.length + " characters",
      content: selected.content,
      tags: true,
      border: 'line',
      draggable: true,
      style: {
        bg: '#333333',
        border: {
          fg: 'blue'
        }
      },
      padding: {
        left: 2,
        top: 2,
        right: 2,
        bottom: 2
      }
    });
    screen.append(modal);
    modal.focus();
    modal.setFront();
    return modal.key('enter', function() {
      return modal.destroy();
    });
  });
  boxen[i].list.on('focus', function() {
    return boxen[i].list.setFront();
  });
  boxen[i].list.key(['up', 'down'], function() {
    if (shift.index !== false && boxen[i].list.selected !== shift.index) {
      boxen[i].list.setItem(shift.index, shift.value);
      screen.render();
      return shift.reset();
    }
  });
  boxen[i].list.key('$', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift.cursor = boxen[i].list.value.length - boxen[i].list.width + 3;
      boxen[i].shift(i);
      return screen.render();
    }
  });
  boxen[i].list.key('^', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift.cursor = 0;
      boxen[i].shift(i);
      return screen.render();
    }
  });
  boxen[i].list.key('right', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift.cursor++;
      boxen[i].shift(i);
      return screen.render();
    }
  });
  boxen[i].list.key('space', function() {
    if (boxen[i].list.value.length > boxen[i].list.width) {
      shift.cursor += 10;
      boxen[i].shift(i);
      return screen.render();
    }
  });
  boxen[i].list.key('left', function() {
    if (shift.cursor > 0) {
      shift.cursor--;
      boxen[i].shift(i);
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
  if (shift.box !== false) {
    boxen[shift.box].list.setItem(shift.index, shift.value);
    screen.render();
    shift.reset();
  }
  screen.focusNext();
  return screen.render();
});

screen.key(['S-tab'], function(ch, key) {
  if (shift.box !== false) {
    boxen[shift.box].list.setItem(shift.index, shift.value);
    screen.render();
    shift.reset();
  }
  screen.focusPrevious();
  return screen.render();
});

boxen[0].list.focus();

boxen[0].list.setFront();

screen.render();
