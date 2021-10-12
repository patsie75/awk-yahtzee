@namespace "dice"

## roll 5 dice randomly (excluding "held" dice)
function rnd(dice,    n, i)
{
  for (i=1; i<=5; i++)
  {
    # if die is not on hold, reroll
    if (!dice["hold"][i])
      dice["val"][i] = int(rand() * 6) + 1
  }
}


## print dice
function show(dice,    i, dots, row) {
  delete dots

  # determine dots on dice
  for (i=1; i<=5; i++)
  {
    if (dice["val"][i] % 2) dots[i][5] = 1
    if (dice["val"][i] > 1) dots[i][1] = dots[i][9] = 1
    if (dice["val"][i] > 3) dots[i][3] = dots[i][7] = 1
    if (dice["val"][i] > 5) dots[i][4] = dots[i][6] = 1
  }
  
  # draw top row
  for (i=1; i<=5; i++)
    printf("\033[%sm▄▄▄▄▄▄▄\033[0m   ", yahtzee::color["dice"])
  printf("\n")
  
  # draw dice
  for (row=0; row<3; row++)
  {
    for (i=1; i<=5; i++)
      printf("\033[%d;%dm %c %c %c \033[0m   ", yahtzee::color["dots"], yahtzee::color["dice"]+10, dots[i][row*3+1] ? "▀" : " ", dots[i][row*3+2] ? "▀" : " ", dots[i][row*3+3] ? "▀" : " ")
    printf("\n")
  }
}


## roll dice and print result
function roll(dice, score,    d, i, r, row)
{
  doroll = 1
  for (i=1; i<=5; i++)
    if (dice["hold"][i] == 0)
      doroll = 10

  for (r=1; r<=doroll; r++)
  {
    # roll the dice and show scorecard and dice
    rnd(dice)
    printf("\033[H")
    score::show(dice, score)
    dice::show(dice)
    system("sleep 0.1")
  }
}

