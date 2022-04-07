import 'dart:js';

class Controller {
  final int A;
  final int B;
  final int X;
  final int Y;
  final int L1;
  final int R1;
  final int L2;
  final int R2;
  final int Share;
  final int Options;
  final int L3;
  final int R3;
  final int Up;
  final int Down;
  final int Left;
  final int Right;
  final double Steering;
  final double Throttle;

  Controller(
    this.A,
    this.B,
    this.X,
    this.Y,
    this.L1,
    this.R1,
    this.L2,
    this.R2,
    this.Share,
    this.Options,
    this.L3,
    this.R3,
    this.Up,
    this.Down,
    this.Left,
    this.Right,
    this.Steering,
    this.Throttle,
  );

  factory Controller.fromJSObject(JsObject state) {
    return Controller(
      state['A'],
      state['B'],
      state['X'],
      state['Y'],
      state['L1'],
      state['R1'],
      state['L2'],
      state['R2'],
      state['Share'],
      state['Options'],
      state['L3'],
      state['R3'],
      state['Up'],
      state['Down'],
      state['Left'],
      state['Right'],
      state['Steering'],
      state['Throttle'],
    );
  }
}
