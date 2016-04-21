public class WeatherAppController {
    
    
    public class WeatherAppState {
        public String zipCode {get;set;}
        public String countryCode {get;set;}
        public String continuationState {get;set;}
        public String accountID {get;set;}
            
    }
    
    public class WeatherResult {
        public String temp {get;set;}
        public String pressure {get;set;}
        public String humidity {get;set;}
        public String temp_min {get;set;}
        public String temp_max {get;set;}
        public String sea_level {get;set;}
        public String grnd_level {get;set;}
        public String currentTemperature {get;set;}
        public String zipCode {get;set;}
        public String country {get;set;}
        public String acountID {get;set;}
        
    }
    
    
    
    // Called via JavaScript Remoting
    @RemoteAction
    public static Object getWeather(String zipCode, String country){
        
        WeatherAppState waso = new WeatherAppState();
        waso.accountID = [SELECT id from Account limit 1].id;
        String requestLabel = '';
        String url = 'http://api.openweathermap.org/data/2.5/weather?zip='+zipCode+','+country
                        +'&APPID=881331eacee38611e2c9db4b15ebec51';

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(url);
        waso.zipCode = zipCode;
        waso.countryCode = country;
             
        Continuation con = new Continuation(60);
        waso.continuationState = con.addHttpRequest(req);
        con.state = waso;
        con.continuationMethod = 'callback';        
    
        // Return it to the system for processing
        return con;
    }
    
    //Continuation
    public static Object callback(Object state) {
        WeatherAppState waso =  (WeatherAppState)state;

        HttpResponse response = Continuation.getResponse(waso.continuationState);
    
        Integer statusCode = response.getStatusCode();

         
        if (statusCode >= 2000) {
            return 'Continuation error: ' + response.getBody();
        }
    
        return WeatherAppController.parseJSON(response.getBody(),waso);
    }
    
    private static Object parseJSON(String jsonString, WeatherAppState waso){
        JSONParser parser = JSON.createParser(jsonString);
        WeatherResult wr = new WeatherResult();
        while (parser.nextToken() != null) {
             if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                 (parser.getText() == 'main')) {
                parser.nextToken();
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                     wr = (WeatherResult) parser.readValueAs(WeatherResult.class);
                }
             }
        }
        wr.zipCode = waso.zipCode;
        wr.country = waso.countryCode;
        Decimal kelvin  = Decimal.valueOf(wr.temp_max);
        Decimal farenhiet = ((kelvin - 273.15)* 1.8000) + 32.00;
        wr.currentTemperature = '' + farenhiet;
        wr.acountID = waso.accountid;
        return wr;
    }

}