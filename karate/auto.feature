Feature: Tests auto-generados desde OpenAPI (SWAPI)

# Apunta por defecto a http://localhost:4010 (Prism en tu host)
Background:
  * def baseUrl = karate.get('baseUrl', java.lang.System.getenv('BASE_URL') || 'http://prism:4010')
  * url baseUrl
  * configure headers = { 'Content-Type': 'application/json' }

#
# PEOPLE
#
Scenario: listPeople (GET /people)
  Given path 'people'
  When method get
  Then status 200
  * def isList = karate.typeOf(response) == 'list'
  * if (isList) match response == '#[]'
  * if (!isList) match response.results == '#[]'

Scenario: getPersonById (GET /people/{id})
  * def id = 1
  Given path 'people', id
  When method get
  Then status 200
  And match response ==
    """
    {
      name: '#string',
      height: '#string',
      mass: '#string',
      hair_color: '#string',
      skin_color: '#string',
      eye_color: '#string',
      birth_year: '#string',
      gender: '#string',
      homeworld: '#string',
      films: '#[]',
      species: '#[]',
      vehicles: '#[]',
      starships: '#[]',
      created: '#string',
      edited:  '#string',
      url:     '#string'
    }
    """

Scenario: getPersonById NotFound (GET /people/{id})
  * def id = 9999
  Given path 'people', id
  When method get
  Then status 404


#
# FILMS
#
Scenario: listFilms (GET /films)
  Given path 'films'
  When method get
  Then status 200
  * def isList = karate.typeOf(response) == 'list'
  * if (isList) match response == '#[]'
  * if (!isList) match response.results == '#[]'

Scenario: getFilmById (GET /films/{id})
  * def id = 2
  Given path 'films', id
  When method get
  Then status 200
  And match response ==
    """
    {
      title: '#string',
      episode_id: '#number',
      opening_crawl: '#string',
      director: '#string',
      producer: '#string',
      release_date: '#string',
      characters: '#[]',
      planets: '#[]',
      starships: '#[]',
      vehicles: '#[]',
      species: '#[]',
      created: '#string',
      edited:  '#string',
      url:     '#string'
    }
    """

Scenario: getFilmById NotFound (GET /films/{id})
  * def id = 9999
  Given path 'films', id
  When method get
  Then status 404


#
# PLANETS
#
Scenario: listPlanets (GET /planets)
  Given path 'planets'
  When method get
  Then status 200
  * def isList = karate.typeOf(response) == 'list'
  * if (isList) match response == '#[]'
  * if (!isList) match response.results == '#[]'

Scenario: getPlanetById (GET /planets/{id})
  * def id = 1
  Given path 'planets', id
  When method get
  Then status 200
  And match response ==
    """
    {
      name: '#string',
      rotation_period: '#string',
      orbital_period: '#string',
      diameter: '#string',
      climate: '#string',
      gravity: '#string',
      terrain: '#string',
      surface_water: '#string',
      population: '#string',
      residents: '#[]',
      films: '#[]',
      created: '#string',
      edited:  '#string',
      url:     '#string'
    }
    """

Scenario: getPlanetById NotFound (GET /planets/{id})
  * def id = 9999
  Given path 'planets', id
  When method get
  Then status 404

#
# STARSHIPS
#
Scenario: listStarships (GET /starships)
  Given path 'starships'
  When method get
  Then status 200
  * def isList = karate.typeOf(response) == 'list'
  * if (isList) match response == '#[]'
  * if (!isList) match response.results == '#[]'

Scenario: getStarshipById (GET /starships/{id})
  * def id = 2
  Given path 'starships', id
  When method get
  Then status 200
  And match response ==
    """
    {
      name: '#string',
      model: '#string',
      manufacturer: '#string',
      cost_in_credits: '#string',
      length: '#string',
      max_atmosphering_speed: '#string',
      crew: '#string',
      passengers: '#string',
      cargo_capacity: '#string',
      consumables: '#string',
      hyperdrive_rating: '#string',
      MGLT: '#string',
      starship_class: '#string',
      pilots: '#[]',
      films: '#[]',
      created: '#string',
      edited:  '#string',
      url:     '#string'
    }
    """

Scenario: getStarshipById NotFound (GET /starships/{id})
  * def id = 9999
  Given path 'starships', id
  When method get
  Then status 404


#
# SPECIES
#
Scenario: listSpecies (GET /species)
  Given path 'species'
  When method get
  Then status 200
  * def isList = karate.typeOf(response) == 'list'
  * if (isList) match response == '#[]'
  * if (!isList) match response.results == '#[]'

Scenario: getSpeciesById (GET /species/{id})
  * def id = 1
  Given path 'species', id
  When method get
  Then status 200
  And match response ==
    """
    {
      name: '#string',
      classification: '#string',
      designation: '#string',
      average_height: '#string',
      skin_colors: '#string',
      hair_colors: '#string',
      eye_colors: '#string',
      average_lifespan: '#string',
      homeworld: '#string',
      language: '#string',
      people: '#[]',
      films:  '#[]',
      created: '#string',
      edited:  '#string',
      url:     '#string'
    }
    """

Scenario: getSpeciesById NotFound (GET /species/{id})
  * def id = 9999
  Given path 'species', id
  When method get
  Then status 404


#
# VEHICLES
#
Scenario: listVehicles (GET /vehicles)
  Given path 'vehicles'
  When method get
  Then status 200
  * def isList = karate.typeOf(response) == 'list'
  * if (isList) match response == '#[]'
  * if (!isList) match response.results == '#[]'

Scenario: getVehicleById (GET /vehicles/{id})
  * def id = 4
  Given path 'vehicles', id
  When method get
  Then status 200
  And match response ==
    """
    {
      name: '#string',
      model: '#string',
      manufacturer: '#string',
      cost_in_credits: '#string',
      length: '#string',
      max_atmosphering_speed: '#string',
      crew: '#string',
      passengers: '#string',
      cargo_capacity: '#string',
      consumables: '#string',
      vehicle_class: '#string',
      pilots: '#[]',
      films:  '#[]',
      created: '#string',
      edited:  '#string',
      url:     '#string'
    }
    """

Scenario: getVehicleById NotFound (GET /vehicles/{id})
  * def id = 9999
  Given path 'vehicles', id
  When method get
  Then status 404

