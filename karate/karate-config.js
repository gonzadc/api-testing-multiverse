function fn() {
  var baseUrl = karate.get('baseUrl', java.lang.System.getenv('BASE_URL') || 'http://localhost:4010');
  return { baseUrl: baseUrl };
}
