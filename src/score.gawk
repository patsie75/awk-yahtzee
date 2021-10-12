@namespace "score"

BEGIN {
  for (i=0; i<256; i++)
    ORD[sprintf("%c", i)] = i
}

## print scorecard
function show(dice, score,    n, i, sum)
{
  sum = 0

  ## header
  printf("\n---[ %s ]-------------------------\n", yahtzee::str[14])

  ## ones through sixes
  for (i=1; i<=6; i++)
  {
    if (score[i] == -1)
    {
      n = yahtzee::check(dice, i)
      printf("-> [%c] %-25s: %3s (%2s)\n", i+96, yahtzee::str[i], "...", (n != -1) ? n : 0)
    } else
      printf("   [%c] %-25s: %3s\n", i+96, yahtzee::str[i], score[i])

    sum += (score[i] == -1) ? 0 : score[i]
  }

  ## score >= 63 bonus
  printf("       %-25s: %3d (%2s)\n", yahtzee::str[15], (sum >= 63) ? 35 : 0, sum)
  if (sum >= 63) sum += 35

  ## combo scores
  for (i=7; i<=13; i++)
  {
    if (score[i] == -1)
    {
      n = yahtzee::check(dice, i)
      printf("-> [%c] %-25s: %3s (%2s)\n", i+96, yahtzee::str[i], "...", (n != -1) ? n : 0)
    } else
      printf("   [%c] %-25s: %3s\n", i+96, yahtzee::str[i], score[i])

    sum += (score[i] == -1) ? 0 : score[i]
  }

  ## Total score
  printf("       %-25s: %3d\n", yahtzee::str[16], sum)
}


## read (encoded) highscores from file
function load(highscore,    file, cmd, i)
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
function add(highscore, score,    i, sum)
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
function save(highscore,    i, cmd, file)
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
function show2(highscore,    i)
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

