source("R/functions.r")

# First part: getting the paths to the movies page --------------------
url_base <- "https://letterboxd.com"
user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.3" # nolint
num_pages <- 1

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

movies_path_list <- furrr::future_map(resps_pl, ~ safe_get_movies_path(.x) |>
    purrr::pluck("result")
)

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

movies_data <- furrr::future_map(resps_ml, ~ safe_get_movies_data(.x) |>
    purrr::pluck("result")
)

# Third part: tidy the data -------------------------------------------
movies_data <- do.call(rbind, movies_data) |>
  data.frame()

final_movies_data <- movies_data |>
  dplyr::mutate(across(everything(), as.character)) |>
  dplyr::mutate(across(everything(), ~ gsub("NULL", NA, .))) |>
  dplyr::mutate(across(c(rating, num_ratings), as.numeric))

# Fourth part: save the data ------------------------------------------
saveRDS(final_movies_data, "data/movies_data.rds")
