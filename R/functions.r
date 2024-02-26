safe_get_movies_path <- purrr::safely(function(response) {
  httr2::resp_body_html(response) |>
    rvest::html_elements(".film-poster") |>
    rvest::html_attr("data-target-link")
})

safe_get_movies_data <- purrr::safely(function(movie_path) {
  html_response <- httr2::resp_body_html(movie_path)
  json_data <- html_response |>
    rvest::html_elements(
      xpath = "//script[@type = 'application/ld+json']"
    ) |>
    rvest::html_text() |>
    jsonlite::fromJSON()
  movie_data <- list(
    title = json_data[["name"]],
    actors = na.omit(json_data[["actors"]][["name"]][1:15]) |>
      paste(collapse = ", "), # Only the first 15 actors
    director = json_data[["director"]][["name"]] |>
      paste(collapse = ", "),
    producer = json_data[["productionCompany"]][["name"]] |>
      paste(collapse = ", "),
    rating = json_data[["aggregateRating"]][["ratingValue"]],
    num_ratings = json_data[["aggregateRating"]][["ratingCount"]],
    year = json_data[["releasedEvent"]][["startDate"]],
    genres = json_data[["genre"]] |>
      paste(collapse = ", "),
    img_url = json_data[["image"]]
  )
})
