#!/usr/bin/gawk -f

@namespace "yahtzee"

BEGIN {
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
  str[19] = "Hold"
  str[20] = "Choose score"
  str[21] = "Top-10 highscores"

  color["black"]   = 30
  color["red"]     = 31
  color["green"]   = 32
  color["yellow"]  = 33
  color["blue"]    = 34
  color["magenta"] = 35
  color["cyan"]    = 36
  color["white"]   = 37

  color["bright"]  = 60

  color["dice"] = ENVIRON["dice"] ? color[ENVIRON["dice"]] : color["red"]
  color["dots"] = ENVIRON["dots"] ? color[ENVIRON["dots"]] : color["white"] + color["bright"]
}

## overwrite language strings with localized translations
function loadlang(str, lang)
{
  # read file from lang folder
  f = "lang/" lang ".lang"
  while ((getline <f) > 0)
  {
    # skip comments, read key=value fields
    if ( ($0 !~ /^ *(#|;)/) && (match($0, /([^=]+)=(.+)/, keyval) > 0) )
    {
      # strip leading and trailing spaces and double-quotes
      gsub(/^\s*"?|"?\s*$/, "", keyval[1])
      gsub(/^\s*"?|"?\s*$/, "", keyval[2])

      # if key is in range of our translation strings, replace it
      if ((int(keyval[1]) >= 1) && (int(keyval[1]) <= 21))
        str[keyval[1]] = keyval[2]
    }
  }
}


## roll 5 dice randomly (excluding "held" dice)
function dice_rnd(dice,    n, i)
{
  for (i=1; i<=5; i++)
  {
    if (!dice["hold"][i])
      dice["val"][i] = int(rand() * 6) + 1
  }
}


## print dice
function dice_print(dice,    d, i, row) {
  # determine dots on dice
  delete d
  for (i=1; i<=5; i++)
  {
    if (dice["val"][i] % 2) d[i][5] = 1
    if (dice["val"][i] > 1) d[i][1] = d[i][9] = 1
    if (dice["val"][i] > 3) d[i][3] = d[i][7] = 1
    if (dice["val"][i] > 5) d[i][4] = d[i][6] = 1
  }
  
  # draw top row
  for (i=1; i<=5; i++)
    printf("\033[%sm▄▄▄▄▄▄▄\033[0m   ", color["dice"])
  printf("\n")
  
  # draw dice
  for (row=0; row<3; row++)
  {
    for (i=1; i<=5; i++)
      printf("\033[%d;%dm %c %c %c \033[0m   ", color["dots"], color["dice"]+10, d[i][row*3+1] ? "▀" : " ", d[i][row*3+2] ? "▀" : " ", d[i][row*3+3] ? "▀" : " ")
    printf("\n")
  }
}


## roll dice and print result
function dice_roll(dice, score,    d, i, r, row)
{
  doroll = 1
  for (i=1; i<=5; i++)
    if (dice["hold"][i] == 0)
      doroll = 10

  for (r=1; r<=doroll; r++)
  {
    # roll the dice and print scorecard and dice
    dice_rnd(dice)
    printf("\033[H")
    scorecard_print(dice, score)
    dice_print(dice)
    system("sleep 0.1")
  }
}


## ask which dice to "hold"
function dice_hold(dice,    n, i, x, arr)
{
  printf("%s 1-6: ", str[19])
  if (getline > 0)
  {
    # no input, everything stays the same
    if (NF == 0) return

    # reset "hold" on each die
    for (i=1; i<=5; i++)
      dice["hold"][i] = 0

    x = split($1, arr, "")
    for (i=1; i<=x; i++)
    {
      ## old-style index hold
      # if (arr[i] in dice["hold"])
      #   dice["hold"][arr[i]] = 1

      ## new style "value" hold
      for (n=1; n<=5; n++)
      {
        if ( (arr[i] == dice["val"][n]) && !dice["hold"][n])
        {
          dice["hold"][n] = 1
          break
        }
      }
    }
  }
}


## check and return possible dice score
function check(dice, n,    sorted, i, x, sum)
{
  awk::asort(dice["val"], sorted)

  if (sorted[1] == -1)
    return(-1)

  ## chance
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


## print scorecard
function scorecard_print(dice, score,    n, i, sum)
{
  sum = 0

  ## header
  printf("\n---[ %s ]-------------------------\n", str[14])

  ## ones through sixes
  for (i=1; i<=6; i++)
  {
    if (score[i] == -1)
    {
      n = check(dice, i)
      printf("-> [%2d] %-20s: %3s (%2s)\n", i, str[i], "...", (n != -1) ? n : 0)
    } else
      printf("   [%2d] %-20s: %3s\n", i, str[i], score[i])

    sum += (score[i] == -1) ? 0 : score[i]
  }

  ## score >= 63 bonus
  printf("        %-20s: %3d (%2s)\n", str[15], (sum >= 63) ? 35 : 0, sum)
  if (sum >= 63) sum += 35

  ## combo scores
  for (i=7; i<=13; i++)
  {
    if (score[i] == -1)
    {
      n = check(dice, i)
      printf("-> [%2d] %-20s: %3s (%2s)\n", i, str[i], "...", (n != -1) ? n : 0)
    } else
      printf("   [%2d] %-20s: %3s\n", i, str[i], score[i])

    sum += (score[i] == -1) ? 0 : score[i]
  }

  ## Total score
  printf("        %-20s: %3d\n", str[16], sum)
}


## ask which score to pick from the scorecard
function scorecard_choose(dice, score,     i, n)
{
  while (1)
  {
    i = -1
    ## check valid input (1-13)
    while ((i<1) || (i>13))
    {
      printf("%s: ", str[20])
      if (getline > 0)
        i = int($1)
    }

    ## if unused score
    if (score[i] == -1)
    { 
      ## get + add score to card
      n = check(dice, i)
      score[i] = (n != -1) ? n : 0
      return
    }
  }

}


## read (encoded) highscores from file
function readhighscore(highscore,    file, cmd, i)
{
  file = ENVIRON["HOME"] "/.yahtzee"
  cmd = sprintf("base64 -d \"%s\"", file)

  i = 0
  while ((cmd | getline) > 0)
  {
    if (NF == 3)
    {
      i++
      highscore[i]["time"] = $1
      highscore[i]["user"] = $2
      highscore[i]["score"] = $3
    }
  }

  close(cmd)
}


## add a score to the highscores list
function addhighscore(highscore, score,    i, sum)
{
  ## ones through sixes
  for (i=1; i<=6; i++)
    sum += (score[i] == -1) ? 0 : score[i]

  ## score >= 63 bonus
  if (sum >= 63) sum += 35

  ## combo scores
  for (i=7; i<=13; i++)
    sum += (score[i] == -1) ? 0 : score[i]

  ## add our score to the highscore list (if applicable)
  for (i=10; i>=1; i--)
  {
    if (sum > highscore[i]["score"])
    {
      ## move previous score one "down"
      highscore[i+1]["time"] = highscore[i]["time"]
      highscore[i+1]["user"] = highscore[i]["user"]
      highscore[i+1]["score"] = highscore[i]["score"]

      ## put our score in its place
      highscore[i]["time"] = awk::systime()
      highscore[i]["user"] = ENVIRON["USER"]
      highscore[i]["score"] = sum
    } else {
      return
    }
  }
}


## writes highscores (encoded) to file
function writehighscore(highscore,    i, cmd, file)
{
  cmd = "base64"
  file = ENVIRON["HOME"] "/.yahtzee"

  ## encode highscores
  for (i=1; i<=10; i++)
    printf("%s %s %s\n", highscore[i]["time"], highscore[i]["user"], highscore[i]["score"]) |& cmd
  close(cmd, "to")

  ## write encoded output
  while ((cmd |& getline) > 0)
    printf("%s\n", $0) > file

  close(cmd)
  close(file)
}


## print list of highscores
function printhighscore(highscore,    i)
{
  # print top-10 highscore list
  for (i=1; i<=10; i++)
  {
    if (highscore[i]["score"] > 0)
      printf("#%2d: %15s, %3dpts (%s)\n", i, highscore[i]["user"], highscore[i]["score"], awk::strftime("%Y/%m/%d %H:%M:%S", highscore[i]["time"]) )
    else
      printf("#%2d: %15s, %6s (%s)\n", i, "yournamehere", "no pts", "has not happened yet" )
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
  yahtzee::loadlang(yahtzee::str, substr(ENVIRON["LANG"],1,5) )

  # read all-time highscores
  yahtzee::readhighscore(highscore)

  # reset scorecard values
  for (i=1; i<=13; i++)
    score[i] = -1

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
      yahtzee::dice_roll(dice, score)
      (roll < 3) ? yahtzee::dice_hold(dice) : yahtzee::scorecard_choose(dice, score)
    }
  }

  # print end result
  printf("\033[2J\033[H%s %2d/13 %s %d/3\n", yahtzee::str[17], turn, yahtzee::str[18], roll)
  printf("\033[H")
  yahtzee::scorecard_print(dice, score)
  yahtzee::dice_print(dice)

  # add score to highscore
  yahtzee::addhighscore(highscore, score)
  printf("%s\n", yahtzee::str[21])
  yahtzee::printhighscore(highscore)
  yahtzee::writehighscore(highscore)
}
