#!/usr/bin/gawk -f

@namespace "yahtzee"

BEGIN {
  label[1] = "Ones"
  label[2] = "Twos"
  label[3] = "Threes"
  label[4] = "Fours"
  label[5] = "Fives"
  label[6] = "Sixes"
  label[7] = "Three of a Kind"
  label[8] = "Four of a Kind"
  label[9] = "Full House"
  label[10] = "Small Straight"
  label[11] = "Large Straight"
  label[12] = "Yahtzee"
  label[13] = "Chance"
}

function sizeof(arr,    i, cnt)
{
  for (i in arr) cnt++
  return cnt;
}

function roll(dice,    n, i)
{
  n = sizeof(dice["val"])

  for (i=1; i<=n; i++)
  {
    if (!dice["hold"][i])
      dice["val"][i] = int(rand() * 6) + 1
  }
}

function show(dice,    n, i)
{
  printf("die: ")
  for (i=1; i<=5; i++)
    printf("(%d) ", i)
  printf("\n")

  printf("val: ")
  for (i=1; i<=5; i++)
    printf("%c%d%c ", dice["hold"][i] ? "[" : " ", dice["val"][i], dice["hold"][i] ? "]" : " ")
  printf("\n")
}

function hold(dice,    n, i, x, arr)
{
  printf("hold 1/2/3/4/5: ")
  if (getline > 0)
  {
    if ($1 ~ /^[Qq]/) return

    n = sizeof(dice["val"])
    for (i=1; i<=n; i++)
      dice["hold"][i] = 0

    x = split($1, arr, "")
    for (i=1; i<=x; i++)
    {
      if (arr[i] in dice["hold"])
        dice["hold"][arr[i]] = 1
    }
  }
}

function check(dice, n,    sorted, i, x, sum)
{
  awk::asort(dice["val"], sorted)

  if (sorted[1] == -1)
    return("-1:-1")

  ## yahtzee
  if ( \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) \
  && (n == 12)) return ("12:50")

  ## large straight
  if ( \
    (sorted[1] == sorted[2]-1) && \
    (sorted[2] == sorted[3]-1) && \
    (sorted[3] == sorted[4]-1) && \
    (sorted[4] == sorted[5]-1) \
  && (n == 11)) return ("11:40")

  ## small straight
  if ( ( ( \
    (sorted[1] == sorted[2]-1) && \
    (sorted[2] == sorted[3]-1) && \
    (sorted[3] == sorted[4]-1) ) || ( \
    (sorted[1] == sorted[2]-1) && \
    (sorted[2] == sorted[3]-1) && \
    (sorted[3] == sorted[5]-1) ) || ( \
    (sorted[1] == sorted[2]-1) && \
    (sorted[2] == sorted[4]-1) && \
    (sorted[3] == sorted[5]-1) ) || ( \
    (sorted[1] == sorted[2]-1) && \
    (sorted[3] == sorted[4]-1) && \
    (sorted[4] == sorted[5]-1) ) || ( \
    (sorted[2] == sorted[3]-1) && \
    (sorted[3] == sorted[4]-1) && \
    (sorted[4] == sorted[5]-1) ) ) \
  && (n == 10)) return ("10:30")

  ## full house
  if ( ( ( \
    (sorted[1] == sorted[2]) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) ) || ( \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) && \
    (sorted[4] == sorted[5]) ) ) \
  && (n == 9)) return ("9:25")

  ## four of a kind
  if ( \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) \
  && (n == 8)) return ("8:" sorted[1] + sorted[2] + sorted[3] + sorted[4])
  if ( \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) \
  && (n == 8)) return ("8:" sorted[2] + sorted[3] + sorted[4] + sorted[5])

  ## three of a kind
  if ( \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) \
  && (n == 7)) return ("7:" sorted[1] + sorted[2] + sorted[3])
  if ( \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) \
  && (n == 7)) return ("7:" sorted[2] + sorted[3] + sorted[4])
  if ( \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) \
  && (n == 7)) return ("7:" sorted[3] + sorted[4] + sorted[5])

  for (i=6; i>0; i--)
  {
    sum = 0
    if (i == n)
    {
      for (x=1; x<=5; x++)
        sum += (sorted[x] == n) ? sorted[x] : 0
      return (n ":" sum)
    }
  }

  if (n == 13)
    return ("13:" sorted[1] + sorted[2] + sorted[3] + sorted[4] + sorted[5])

  return("-1:-1")
}

function scorecard_print(dice, score,    n, i, sum)
{
  sum = 0

  printf("\n---[ scorecard ]-------------------------\n")
  for (i=1; i<=6; i++)
  {
    split(check(dice, i), n, ":")
    if (score[i] == -1)
      printf("-> [%2d] %-20s: %3s (%2s)\n", i, label[i], "...", (n[2] != -1) ? n[2] : 0)
    else
      printf("   [%2d] %-20s: %3s\n", i, label[i], score[i])

    sum += (score[i] == -1) ? 0 : score[i]
  }

  printf("        %-20s: %3d (%2s)\n", "Bonus if score >=63", (sum >=63) ? 35 : 0, sum)
  if (sum >= 63)
    sum += 35

  for (i=7; i<=13; i++)
  {
    split(check(dice, i), n, ":")
    if (score[i] == -1)
      printf("-> [%2d] %-20s: %3s (%2s)\n", i, label[i], "...", (n[2] != -1) ? n[2] : 0)
    else
      printf("   [%2d] %-20s: %3s\n", i, label[i], score[i])
    sum += (score[i] == -1) ? 0 : score[i]
  }
  printf("        %-20s: %3d\n", "Total score", sum)
}

function scorecard_choose(dice, score,     i, n)
{
  while (1)
  {
    i = -1
    while ((i<1) || (i>13))
    {
      printf("choose score: ")
      if (getline > 0)
        i = int($1)
    }

    split(check(dice, i), n, ":")
 
    if (score[i] == -1)
    { 
      score[i] = (n[2] == -1) ? 0 : n[2]
      return
    }
  }

}

function dice_reset(dice,    i)
{
  for (i=1; i<=5; i++)
  {
    dice["val"][i] = 1
    dice["hold"][i] = 0
  }
}


@namespace "awk"
BEGIN {
  srand()

  for (i=1; i<=5; i++)
    empty["val"][i] = -1

  for (i=1; i<=13; i++)
    score[i] = -1

  for (turn=1; turn<=13; turn++)
  {
    yahtzee::dice_reset(dice)

    for (roll=1; roll<=2; roll++)
    {
      printf("\033[2J\033[HTurn %2d/13 roll %d/3\n", turn, roll)
      yahtzee::roll(dice)
      yahtzee::show(dice)
      yahtzee::scorecard_print(empty, score)
      yahtzee::hold(dice)
    }
    printf("\033[2J\033[HTurn %2d/13 roll %d/3\n", turn, roll)
    yahtzee::roll(dice)
    yahtzee::show(dice)
    yahtzee::scorecard_print(dice, score)
    yahtzee::scorecard_choose(dice, score)
  }

  printf("\033[2J\033[HTurn %2d/13 roll %d/3\n", turn, roll)
  yahtzee::show(dice)
  yahtzee::scorecard_print(dice, score)
}
