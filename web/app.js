function canGame() {
  return "getGamepads" in navigator;
}

function reportOnGamepad() {
  var gp = navigator.getGamepads()[0];
  window.state = {
    A: gp.buttons[0].value,
    B: gp.buttons[2].value,
    X: gp.buttons[1].value,
    Y: gp.buttons[3].value,
    L1: gp.buttons[4].value,
    R1: gp.buttons[5].value,
    L2: gp.buttons[6].value,
    R2: gp.buttons[7].value,
    Share: gp.buttons[8].value,
    Options: gp.buttons[9].value,
    L3: gp.buttons[10].value,
    R3: gp.buttons[11].value,
    Up: gp.buttons[12].value,
    Down: gp.buttons[13].value,
    Left: gp.buttons[14].value,
    Right: gp.buttons[15].value,
    Steering: gp.axes[0],
    Throttle: gp.axes[1],
  };
}

$(document).ready(function () {
  if (canGame()) {
    $(window).on("gamepadconnected", function () {
      hasGP = true;
      console.log("connection event");
      repGP = window.setInterval(reportOnGamepad, 50);
    });

    $(window).on("gamepaddisconnected", function () {
      console.log("disconnection event");
      window.clearInterval(repGP);
    });
  }
});
