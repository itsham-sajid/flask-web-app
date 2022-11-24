import os
import random
import requests
from dotenv import load_dotenv
from flask import Flask, render_template


load_dotenv()

app = Flask(__name__)


@app.route('/')

def main():

    '''Function runs a get request to API and returns data in JSON'''

    api_key = os.getenv("API_KEY")
    api_url = "https://api.themoviedb.org/3/movie/popular"


    get_request = requests.get(api_url, params={'api_key':api_key}, timeout=10)
    data = get_request.json()

    popular_movies = data["results"]
    suggested_movie = [random.choice(popular_movies)]

    movie_name = suggested_movie[0]["title"]
    release_date = suggested_movie[0]["release_date"]
    overview = suggested_movie[0]["overview"]
    rating = suggested_movie[0]["vote_average"]
    movie_poster = suggested_movie[0]["poster_path"]

    poster_path_url = "https://www.themoviedb.org/t/p/w220_and_h330_face"
    
    return render_template('index.html', movie_name=movie_name, release_date=release_date, overview=overview, rating=rating, movie_poster=movie_poster, poster_path_url=poster_path_url)
