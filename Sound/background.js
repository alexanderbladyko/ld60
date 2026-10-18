setcpm(32);

stack(
  s("~ pink pink")
    .attack(0.001)
    .decay(0.025)
    .sustain(0)
    .release(0.01)
    .hpf(3500)
    .gain(0.025),

  cat(
    "d5 a4 d5 f5 e5 d5",
    "e5 g5 e5 c5@2 ~",
    "d5 g5 a5 b5 a5 g5",
    "e5 c5 a4 e5@2 ~",

    "f5 a5 g5 f5 e5 d5",
    "e5 g5 c6 b5 a5 g5",
    "b5 a5 g5 d5 e5 g5",
    "e5 c#5 a4 c#5 e5 a5",

    "f5 a5 d6 a5 g5 f5",
    "g5 e5 c5 e5@2 ~",
    "g5 b5 d6 b5 a5 g5",
    "a5 e5 c5 a4@2 ~",

    "d5 f5 a5 f5 e5 d5",
    "e5 g5 c6 g5 e5 c5",
    "d5 g5 b5 a5 g5 e5",
    "c#5 e5 a5 e5 c#5 a4",
  )
    .note()
    .sound("gm_flute")
    .attack(0.025)
    .release(0.12)
    .gain(0.55)
    .room(0.18),

  cat(
    "d4 a4 f4 a4 f4 a4",
    "c4 g4 e4 g4 e4 g4",
    "g3 d4 b3 d4 b3 d4",
    "a3 e4 c4 e4 c4 e4",

    "d4 a4 f4 a4 f4 a4",
    "c4 g4 e4 g4 e4 g4",
    "g3 d4 b3 d4 b3 d4",
    "a3 e4 c#4 e4 c#4 e4",
  )
    .note()
    .sound("gm_acoustic_guitar_nylon")
    .release(0.12)
    .gain("0.32 0.18 0.25 0.18 0.25 0.18"),

  cat(
    "d3 a3 a3",
    "c3 g3 g3",
    "g2 d3 d3",
    "a2 e3 e3",

    "d3 a3 a3",
    "c3 g3 g3",
    "g2 d3 d3",
    "a2 e3 e3",
  )
    .note()
    .sound("triangle")
    .attack(0.015)
    .decay(0.22)
    .sustain(0)
    .release(0.08)
    .gain("0.3 0.15 0.15"),
);
