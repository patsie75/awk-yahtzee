@namespace "lang"

## overwrite language strings with localized translations
function load(str, lang,    f, keyval)
{
  # read file from lang folder
  f = "lang/" lang ".str"
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

