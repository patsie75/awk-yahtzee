#!/usr/bin/gawk -f

@include "src/lang.gawk"
@include "src/score.gawk"
@include "src/dice.gawk"

@namespace "yahtzee"

BEGIN {
  # language strings
  str[1] = "Ones"
  str[2] = "Twos"
  str[3] = "Threes"
  str[4] = "Fours"
  str[5] = "Fives"
  str[6] = "Sixes"
  str[7] = "Three of a Kind"
  str[8] = "Four of a Kind"
  str[9] = "Full House"
  str[10] = "Small Straight"
  str[11] = "Large Straight"
  str[12] = "Yahtzee"
  str[13] = "Chance"
  str[14] = "Scorecard"
  str[15] = "Bonus if score >=63"
  str[16] = "Total score"
  str[17] = "Turn"
  str[18] = "Roll"
  str[19] = "Choose 1-6, a-m"
  str[20] = "Choose a-m"
  str[21] = "Top-10 highscores"

  # color constants
  color["black"]   = 30
  color["red"]     = 31
  color["green"]   = 32
  color["yellow"]  = 33
  color["blue"]    = 34
  color["magenta"] = 35
  color["cyan"]    = 36
  color["white"]   = 37

  color["bright"]  = 60

  # dice and dots can be changed through environment variables "dice" and "dots"
  # i.e.: dice=blue dots=yellow ./yahtzee.gawk
  color["dice"] = (ENVIRON["dice"] == "random") ? color[randcolor()] : (ENVIRON["dice"] in color) ? color[ENVIRON["dice"]] : color["red"]
  color["dots"] = (ENVIRON["dots"] in color) ? color[ENVIRON["dots"]] : color["white"] + color["bright"]
}

## pick a random color from the available colors
function randcolor(    n, c, rnd)
{
  srand()

  # exclude white
  n = split("black red green yellow blue magenta cyan", c)
  rnd = int(rand() * n) + 1
  return c[rnd]
}

## check and return possible dice score
function check(dice, n,    sorted, i, x, sum)
{
  # sort dice from low to high
  awk::asort(dice["val"], sorted)

  if (sorted[1] == -1)
    return(-1)

  # chance
  if (n == 13)
    return (sorted[1] + sorted[2] + sorted[3] + sorted[4] + sorted[5])

  ## yahtzee
  if ( (n == 12) && \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) \
  ) return (50)

  ## large straight
  if ( (n == 11) && \
    (sorted[1] == sorted[2]-1) && \
    (sorted[2] == sorted[3]-1) && \
    (sorted[3] == sorted[4]-1) && \
    (sorted[4] == sorted[5]-1) \
  ) return (40)

  ## small straight
  if ( (n == 10) && ( ( \
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
  ) return (30)

  ## full house
  if ( (n == 9) && ( ( \
    (sorted[1] == sorted[2]) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) ) || ( \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) && \
    (sorted[4] == sorted[5]) ) ) \
  ) return (25)

  ## four of a kind
  if ( (n == 8) && \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) \
  ) return (sorted[1] + sorted[2] + sorted[3] + sorted[4])
  if ( (n == 8) && \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) \
  ) return (sorted[2] + sorted[3] + sorted[4] + sorted[5])

  ## three of a kind
  if ( (n == 7) && \
    (sorted[1] == sorted[2]) && \
    (sorted[2] == sorted[3]) \
  ) return (sorted[1] + sorted[2] + sorted[3])
  if ( (n == 7) && \
    (sorted[2] == sorted[3]) && \
    (sorted[3] == sorted[4]) \
  ) return (sorted[2] + sorted[3] + sorted[4])
  if ( (n == 7) && \
    (sorted[3] == sorted[4]) && \
    (sorted[4] == sorted[5]) \
  ) return (sorted[3] + sorted[4] + sorted[5])

  ## ones, twos, threes, etc
  for (i=6; i>0; i--)
  {
    if (n == i)
    {
      sum = 0
      for (x=1; x<=5; x++)
        sum += (sorted[x] == n) ? sorted[x] : 0
      return (sum)
    }
  }

  return(-1)
}


function choose(dice, score, canhold,    valid)
{

  # valid input: [a-m]|[1-6]{1,5}
  while (1)
  {
    printf("%s: ", canhold ? yahtzee::str[19] : yahtzee::str[20])
    if (getline > 0)
    {
      switch($1)
      {
      # scorecard value
      case /^[a-m]$/: 
        # translate a-m to 1-13
        i = ORD[$1] - 96

        ## if unused score
        if (score[i] == -1)
        {
          ## get + add score to card
          n = check(dice, i)
          score[i] = (n != -1) ? n : 0
          return 1
        }
        break

      # dice value
      case /^[1-6]{0,5}$/:
        if (canhold)
        {
          # no input, no change
          if (NF == 0) return

          # reset "hold" on each die
          for (i=1; i<=5; i++)
            dice["hold"][i] = 0

          x = split($1, arr, "")
          for (i=1; i<=x; i++)
          {
            # hold a die value
            for (n=1; n<=5; n++)
            {
              if ( (arr[i] == dice["val"][n]) && !dice["hold"][n])
              {
                dice["hold"][n] = 1
                break
              }
            }
          }
          return 0
        }
        break
      }
    }
  }
}

####################
###              ###
### MAIN PROGRAM ###
###              ###
####################

@namespace "awk"
BEGIN {
  srand()

  # load internationalisation strings based on LANG environment variable
  lang::load(yahtzee::str, substr(ENVIRON["LANG"],1,5) )

  # read all-time highscores
  score::load(highscore)

  # reset scorecard values
  for (i=1; i<=13; i++)
    score[i] = -1

  # reset dice
  for (i=1; i<=5; i++)
  {
    dice["val"][i] = -1
    dice["hold"][i] = 0
  }

#  yahtzee::choose(dice, score, 1)
#  exit

  # 13 scores is 13 turns
  for (turn=1; turn<=13; turn++)
  {
    # reset "hold"
    for (i=1; i<=5; i++)
      dice["hold"][i] = 0

    # roll dice three times
    for (roll=1; roll<=3; roll++)
    {
      printf("\033[2J\033[H%s %2d/13 %s %d/3\n", yahtzee::str[17], turn, yahtzee::str[18], roll)
      dice::roll(dice, score)
      #(roll < 3) ? dice::hold(dice) : dice::choose(dice, score)
      if (yahtzee::choose(dice, score, (roll < 3))) break
    }
  }

  # print end result
  printf("\033[2J\033[H%s %2d/13 %s %d/3\n", yahtzee::str[17], turn, yahtzee::str[18], roll)
  printf("\033[H")
  score::show(dice, score)
  dice::show(dice)

  # add score to highscore
  score::add(highscore, score)
  printf("%s\n", yahtzee::str[21])
  score::show2(highscore)
  score::save(highscore)
}
