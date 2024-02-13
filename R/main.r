# First part: getting the paths to the movies page --------------------
url_base <- "https://letterboxd.com"
user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.3" # nolint
num_pages <- 10

req_base_pl <- httr2::request(url_base) |>
  httr2::req_user_agent(user_agent) |>
  httr2::req_url_path(path = "/films/ajax/popular/page/") |>
  httr2::req_url_query(`esiAllowFilters` = "true")

reqs_pl <- furrr::future_map(1:num_pages, ~ {
  req_base_pl |>
    httr2::req_url_path_append(page_number = glue::glue("{.x}/"))
})

resps_pl <- httr2::req_perform_parallel(
  reqs_pl,
  progress = "FP: resps_pl", on_error = "continue"
)

movies_path_list <- furrr::future_map(resps_pl, ~ {
  httr2::resp_body_html(.x) |>
    rvest::html_elements(".film-poster") |>
    rvest::html_attr("data-target-link")
})

movies_path <- unlist(movies_path_list)

# Second part: getting the data from each movie page ------------------
reqs_ml <- furrr::future_map(movies_path, ~ {
  httr2::request(url_base) |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_url_path(path = .x)
})

resps_ml <- httr2::req_perform_parallel(
  reqs_ml,
  progress = "SP: resps_ml", on_error = "continue"
)

movies_data <- furrr::future_map(resps_ml, ~ {
  html_response <- httr2::resp_body_html(.x)
  movie_data <- list(
    title = html_response |>
      rvest::html_elements(".headline-1") |>
      rvest::html_text(),
    actors = html_response |>
      rvest::html_elements(".cast-list .text-slug") |>
      rvest::html_text() |>
      paste0(collapse = ", "),
    director = html_response |>
      rvest::html_elements(
        xpath = "//section[@id = 'featured-film-header']//span"
      ) |>
      rvest::html_text() |>
      paste0(collapse = ", "),
    rating = html_response |>
      rvest::html_elements(
        xpath = "//meta[@name = 'twitter:data2']"
      ) |>
      rvest::html_attr("content"),
    year = html_response |>
      rvest::html_elements(
        xpath = "//section[@id = 'featured-film-header']//small/a"
      ) |>
      rvest::html_text(),
    genres = html_response |>
      rvest::html_elements(
        xpath = "//div[@id = 'tab-genres']//p[position() = 1]/a"
      ) |>
      rvest::html_text() |>
      paste0(collapse = ", "),
    themes = html_response |>
      rvest::html_elements(
        xpath = "//div[@id = 'tab-genres']//div[position() = 2]/p/a"
      ) |>
      rvest::html_text() |>
      paste0(collapse = ", ")
  )
})
