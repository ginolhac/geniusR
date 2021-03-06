#' Use Genius url to retrieve lyrics
#'
#' This function is used inside of the `genius_lyrics()` function. Given a url to a song on Genius, this function returns a tibble where each row is one line. Pair this function with `gen_song_url()` for easier access to song lyrics.
#'
#' @param url The url of song lyrics on Genius
#' @param info Default `"title"`, returns the track title. Set to `"simple"` for only lyrics, `"artist"` for the lyrics and artist, or `"all"` to return the lyrics, artist, and title.
#'
#' @examples
#' url <- gen_song_url(artist = "Kendrick Lamar", song = "HUMBLE")
#' genius_url(url)
#'
#' genius_url("https://genius.com/Head-north-in-the-water-lyrics", info = "all")
#'
#' @export
#' @import dplyr
#' @importFrom rvest html_session html_node
#' @importFrom stringr str_detect
#' @importFrom readr read_lines

genius_url <- function(url, info = "title") {

  # Start a new session
  session <- html_session(url)

  # Clean the song lyrics
  lyrics <- gsub(pattern = "<.*?>",
                 replacement = "\n",
                 html_node(session, ".lyrics")) %>%
    read_lines() %>%
    na.omit() %>%
    str_replace_all("’", "'")

  # Artist
  artist <- html_nodes(session, ".header_with_cover_art-primary_info-primary_artist") %>%
    html_text() %>%
    str_replace_all("\n", "") %>%
    str_trim()

  # Song title
  song_title <- html_nodes(session, ".header_with_cover_art-primary_info-title") %>%
    html_text() %>%
    str_replace_all("\n", "") %>%
    str_trim()

  # Convert to tibble
  lyrics <- tibble(artist = artist,
                   track_title = song_title,
                   lyric = lyrics)

  # Isolate only lines that contain content
  index <- which(str_detect(lyrics$lyric, "[[:alnum:]]") == TRUE)
  lyrics <- lyrics[index,]

  # Remove lines with things such as [Intro: person & so and so]
  lyrics <- lyrics[str_detect(lyrics$lyric, "\\[|\\]") == FALSE, ]
  lyrics <- lyrics %>% mutate(line = row_number())

  switch(info,
         simple = {return(select(lyrics, -artist, -track_title))},
         artist = {return(select(lyrics, -track_title))},
         title = {return(select(lyrics, -artist))},
         all = return(lyrics)
  )
}
