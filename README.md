# 날씨 정보

#### 프로젝트 기간: 2021.09.27 - 2021.10.22 (진행중)
#### 프로젝트 팀원: [Geon](https://github.com/jgkim1008), [Joey](https://github.com/joey-ful)

## I. 앱 기능 소개

## II. 설계/구조
### 1. UML

#### Step1
![image](https://user-images.githubusercontent.com/52592748/135596871-86038b7a-8089-437e-9fbc-5d575c5ead0c.png)
---
![image](https://user-images.githubusercontent.com/52592748/135596932-8a13d9e2-059b-4081-990a-6cf084def32e.png)

#### Step2
![image](https://user-images.githubusercontent.com/52592748/136524713-6bde8fd9-c8fc-4e85-b4dc-6e951e1d626e.png)
---
![image](https://user-images.githubusercontent.com/52592748/136524911-6c96f258-5843-48ea-b372-ff5d8bb28153.png)

#### Final

![Weather_Forecast drawio (2)](https://user-images.githubusercontent.com/52592748/138413309-bb7e4e0f-77f7-435f-9056-54d6046188e1.png)


### 2. 타입별 역할 분배

#### ViewController

#### LocationManager 
* CLLocationManager를 사용하여 위치정보를 수집 후(위도, 경도)를 통해 주소를 가져온다.

#### NetworkManager
* urlRequst를 생성 및 NetworkModule에게 urlRequest를 전달한다.

#### NetworkModule
* urlRequest를 통해 네트워크 통신을 진행한다.

#### WeatherForecastRoute
* WeatherForecastRoute 프로젝트에 맞는 URL 및 URI에 대한 정보를 가지고 있는 타입

#### Decodable + Extension
* 네트워크 통신을 통해 받아온 Data를 파싱해주는 역할

### 3. 모델 구조
### 4. 타입간 관계

## III. 트러블 슈팅

### 1. 중복 요청 처리

#### 문제상황1:
- 중복으로 네트워크 요청을 보내는 경우 중복으로 처리하지 않도록 방어를 하였으나 서로 다른 Requset임에도 불구하고 직전의 URLSessionDataTask를 무조건 cancel하는 문제가 발생했다.
```swift
let dataTask: URLSessionDataTask?
dataTask?.cancel()
dataTask = nil

dataTask = URLSession.shared.dataTask(with: request) {}
dataTask.resume()
```
#### 해결 방법1: URLSessionDataTask의 currentRequest 비교 로직
- URLSessionDataTask를 무조건 cancel하기보다 이전 URLSessionDataTask의 Request와 현재 보낼 HTTP Request가 같으면 cancel하는 로직을 구현했다.
```swift
let dataTask: URLSessionDataTask?
if dataTask.currentRequest == request {
    dataTask?.cancel()
    dataTask = nil
}

dataTask = URLSession.shared.dataTask(with: request) {}
dataTask.resume()
```
#### 문제상황2:
- 같은 Request가 연속적으로 요청되지 않으면 중복 요청임에도 방어가 되지 않음을 확인할 수 있었다. 예를 들어 요청이 A, B, A 순으로 올 경우 두 번의 A 요청이 모두 통신되는 문제가 발생한다.
#### 해결 방법2: URLSessionTask - originalRequset, [URLSessionDataTask]
- originalRequest를 통해 Request object URLSessionDataTask가 생성되었을 때의 request를 알 수 있다.
- 생성되는 URLSessionDataTask를 배열에 저장해두고, 새로운 Request와 배열의 모든 URLSessionDataTask의 Request를 비교한다. 만약 현재 Request와 기존에 진행중이던 Requset가 중복이 되었을 때에는 이전에 요청했던 URLSessionDataTask는 cancel 및 배열에서 삭제되도록 로직을 변경 했다.
```swift
let dataTask = [URLSessionDataTask] = []
dataTask.enumerated().forEach { (index, task) in
    if let originalRequest = task.originalRequest,
       originalRequest == request {
        task.cancel()
        dataTask.remove(at: index)
    }
}
let task = URLSession.shared.dataTask(with: request) {}
task.resume()
dataTask.append(task)
```
### 2. 하나의 메서드에서 여러 종류의 타입을 파싱
현재 앱에서 사용하는 날씨 데이터는 CurrentWeather와 FiveDayWeather라는 두 가지 모델이 존재한다.
두 가지 모델을 파싱하기 위해 모델마다 메서드를 하나씩 만들기보다는 하나의 메서드가 여러 모델을 파싱할 수 있도록 재사용성을 높이는 방향으로 구현하고자 했다.

#### 문제상황 1
데이터모델들(CurrentWeather와 FiveDayWeahter)를 WeatherModel이라는 하나의 Protocol 타입으로 추상화하고 파싱의 결과를 하나의 메서드를 재사용해 처리하도록 시도했다.
🥊 하지만 `extract(data:period:)`메서드에서 Result<CurrentWeather, ParsingError>타입을 Result<WeatherModel, ParsingError> 타입에 담을 수 없다는 에러가 발생했다.
![image](https://user-images.githubusercontent.com/52592748/136514211-9fed3443-380c-423f-beca-3fd68926ec56.png)

- 파싱하는 메서드 `extract(data:period:)`에서 WeatherModel 타입을 받아 파싱하도록 했다.
- 파싱한 결과는 `Result<WeatherModel, ParsingError>`타입으로 반환되기 때문에 여기서 switch문으로 분기처리가 한 번 더 필요했다. 
  - Result 타입의 분기 처리는 `filter(parsedData:)` 라는 별개의 메서드에서 수행해 함수의 기능을 분리하고자 했다.
- `filter(parsedData:)`는 모델의 종류에 따른 처리를 WeatherModel의 데이터를 다시 CurrentWeather나 FiveDayWeather로 다운캐스팅하는 작업으로 처리했다.

<details>
<summary> <b> 문제상황 1 코드 </b>  </summary>
<div markdown="1">

```swift
protocol WeatherModel {}
extension CurrentWeather: WeatherModel {}

private func extract(data: Data, period: WeatherForecastRoute) {
    switch period {
    case .current:
        let parsedData = data.parse(to: CurrentWeather.self)
        filter(parsedData: parsedData)
    case .fiveDay:
        let parsedData = data.parse(to: FiveDayWeather.self)
        filter(parsedData: parsedData)
    }
}

private func filter(parsedData: Result<WeatherModel, ParsingError>) {
    switch parsedData {
    case .success(let data):
        if let weatherData = data as? CurrentWeather {
            currentWeather = weatherData
        } else if let weatherData = data as? FiveDayWeather {
            fiveDayWeather = weatherData
        }
    case .failure(let parsingError):
        assertionFailure(parsingError.localizedDescription)
    }
}
```
</div>
</details>
<br>
  
#### 문제상황 2
- 위 상황을 해결하기 위해 이번에는 파싱하는 로직을 NetworkModule타입으로 이동했다. 
  - 어차피 네트워크 요청에서 받은 데이터는 무조건 파싱을 할 것이라 판단해서 네트워크 통신을 하는 타입이 파싱 역할까지 하도록 한 것이다.
- 이를 위해 네트워크 통신을 담당하는 타입인 NetworkModule을 제니릭 타입으로 변경했다. 두 가지 모델은 여전히 WeatherModel이라는 타입으로 추상화해두었다.
  - NetworkModule을 제네릭으로 수정하면서 NetworkManager와 Networkable 프로토콜도 제네릭으로 변경하게 되었다.
- 뷰컨트롤러에서 `getWeatherData(type:of:route:)`라는 메서드로 CurrentWeather와 FiveDayWeather 종류의 데이터를 모두 받을 수 있는 메서드를 구현했다.
🥊 문제상황 2의 경우 현재까지의 로직은 문제없이 잘 구현되었다. 하지만 뷰컨트롤러에서 `getWeatherData(type:of:route:)`를 사용하는 순간 다음과 같은 에러가 발생했다.
![image](https://user-images.githubusercontent.com/52592748/136516097-78e30c53-0ea4-40cb-a7c5-05b2cc3698e5.png)

<details>
<summary> <b> 문제상황 2가 발생한 지점 - 뷰컨트롤러에서 `getWeatherData(type:of:route:)`를 호출  </b>  </summary>
<div markdown="1">
  
  
```swift
class ViewController: UIViewController {
    private var networkManager = NetworkManager()
    private let locationManager = LocationManager()
    private var currentWeather: CurrentWeather?
    private var fiveDayWeather: FiveDayWeather?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initData()
    }

    private func initData() {
        guard let location = locationManager.getGeographicCoordinates() else {
            return
        }
        
        getWeatherData(type: CurrentWeather, of: location, route: .current)
        getWeatherData(type: FiveDayWeather, of: location, route: .fiveDay)
    }
}
```
  
</div>
</details>
<br>
  
<details>
<summary> <b> 어떤 타입의 날씨든 받아오는 `getWeatherData(type:of:route:)` 코드 </b>  </summary>
<div markdown="1">
  
```swift
protocol WeatherModel: Decodable {}
extension CurrentWeather: WeatherModel {}
extension FiveDayWeather: WeatherModel {}

private func getWeatherData<WeatherModel: Decodable>(type: WeatherModel,
                                                         of location: CLLocation,
                                                         route: WeatherForecastRoute)
    {
    let queryItems = WeatherForecastRoute.createParameters(latitude: location.coordinate.latitude,
                                                           longitude: location.coordinate.longitude)

    networkManager.request(type: type,
                           with: route,
                           queryItems: queryItems,
                           httpMethod: .get,
                           requestType: .requestWithQueryItems) { (result: Result<WeatherModel, Error>) in
        switch result {
        case .success(let data):
            if let weatherData = data as? CurrentWeather {
                self.currentWeather = weatherData
            } else if let weatherData = data as? FiveDayWeather {
                self.fiveDayWeather = weatherData
            }
        case .failure(let error):
            assertionFailure(error.localizedDescription)
        }
    }
}
```
  
</div>
</details>
<br>

  
<details>
<summary> <b> 제네릭 타입으로 변경한 NetworkModule, Networkable, NetworkManager 코드 </b>  </summary>
<div markdown="1">
  

```swift
struct NetworkModule: Networkable {
    private let rangeOfSuccessState = 200...299
    private var dataTask: [URLSessionDataTask] = []
    
    mutating func runDataTask<T: Decodable>(type: T, request: URLRequest,
                              completionHandler: @escaping (Result<T, Error>) -> Void) {
        dataTask.enumerated().forEach { (index, task) in
            if let originalRequest = task.originalRequest,
               originalRequest == request {
                task.cancel()
                dataTask.remove(at: index)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse,
                  rangeOfSuccessState.contains(response.statusCode) else {
                      DispatchQueue.main.async {
                          completionHandler(.failure(NetworkError.badResponse))
                      }
                      return
                  }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(NetworkError.invalidData))
                }
                return
            }
            
            DispatchQueue.main.async {
                let result = data.parse(to: T.self)
                switch result {
                case .success(let parsed):
                    completionHandler(.success(parsed))
                case .failure(let error):
                    completionHandler(.failure(error))
                }
                
            }

        task.resume()
        dataTask.append(task)
    }
}

```

```swift
protocol Networkable {
    mutating func runDataTask<T: Decodable>(type: T, request: URLRequest, completionHandler: @escaping (Result<T,Error>) -> Void)
}
```
  

```swift
struct NetworkManager {
    private var networkable: Networkable
    
    init(networkable: Networkable = NetworkModule()) {
        self.networkable = networkable
    }
    
    mutating func request<T: Decodable>(type: T,
                                        with route: Route,
                          queryItems: [URLQueryItem]?,
                          header: [String: String]? = nil,
                          bodyParameters: [String: Any]? = nil,
                          httpMethod: HTTPMethod,
                          requestType: URLRequestTask,
                          completionHandler: @escaping (Result<T, Error>) -> Void)
    {
        
        guard let urlRequest = requestType.buildRequest(route: route,
                                                        queryItems: queryItems,
                                                        header: header,
                                                        bodyParameters: bodyParameters,
                                                        httpMethod: httpMethod)
        else {
            completionHandler(.failure(NetworkError.invalidURL))
            return
        }
        networkable.runDataTask(type: type, request: urlRequest, completionHandler: completionHandler)
    }
}

```

</div>
</details>
<br>

#### 해결 방법 2
파싱 로직을 뷰컨트롤러에서 수행하도록 코드를 다시 문제상황 1로 되돌렸다. 
- CurrentWeather와 FiveDayWeather를 더이상 하나의 타입으로 추상화할 필요가 없어 해당 로직은 제거했다.
- 그리고 `extract(data:period:)`와 `filter(parsedData:)` 로직을 하나로 합쳐 처리를 해주었다.
- 이제 뷰컨트롤러가 `getWeatherData(type:of:route:)` 메서드를 호출하면 `extract(data:period:)`에서 어떤 모델 타입이든 관계없이 파싱을 수행한다.
함수의 재사용성을 확보했으나 중첩 switch문으로 구현할 수 밖에 없어 가독성이 떨어지는 단점이 생겼다.

```swift
private func extract(data: Data, period: WeatherForecastRoute) {
    switch period {
    case .current:
        let parsedData = data.parse(to: CurrentWeather.self)
        switch parsedData {
        case .success(let currentWeatherData):
            self.currentWeather = currentWeatherData
        case .failure(let parsingError):
            assertionFailure(parsingError.localizedDescription)
        }
    case .fiveDay:
        let parsedData = data.parse(to: FiveDayWeather.self)
        switch parsedData {
        case .success(let fiveDayWeatherData):
            self.fiveDayWeather = fiveDayWeatherData
        case .failure(let parsingError):
            assertionFailure(parsingError.localizedDescription)
        }
    }
}
```

### 3. Address 리턴할 때 옵셔널의 옵셔널 타입이 돼서 고생..
#### 문제상황
- reverseGeocodeLocation() 메서드에서 complitionHandler로 데이터를 가져올때, CLPlacemark의 인스턴스 프로퍼티(administrativeArea,locality,thoroughfare)가 반환타입이 String? 타입이다.
- 위도,경도를 통해 주소를 가져오는 getAddress()메서드는 complitionHander로 Result<[Address:String?]> 타입인데, 이떄 딕셔너리에서 값을 가져올때는 옵셔널로 가져오게 된다.
- 그래서 사용할떄는 옵셔널 바인딩을 2번 해야되는 문제가 발생하였다.

#### 해결 방법
- 위도,경도를 통해 주소를 가져오는 getAddress 에서 CLPlacemark의 인스턴스 프로퍼티를 옵셔널 바인딩을 통하여 옵셔널을 해제한후 딕셔너리에 저장한다.
- 그래서 넘겨줄 때 옵셔널 한 번 벗기고 넘겨주는 것으로 처리 했다.

## IV. 설계시 고려했던 내용

### 네트워크 타입
- 네트워크 통신을 담당하는 타입을 손쉽게 사용할 수 있으면서 재사용성도 높이는 방향으로 설계를 했다.

#### 사용하는 곳에서 통신에 필요한 정보를 간편하게 전달
NetworkManager라는 타입에 하나의 메서드로 통신에 필요한 모든 정보를 전달하고자 했다. 전달할 정보는 URL을 구성하기 위한 요소, 파라미터, HTTP 메서드, 헤더와 바디의 여부 및 형식이 있었다.
- URL을 구성할 필수 항목들은 Route 프로토콜에 담아 프로젝트마다 이를 구체화한 타입을 사용하도록 했다.
- 파라미터는 queryItems와 bodyParameter 이렇게 두 가지 종류가 있었고 이를 하나의 타입으로 묶으면 좋은데 🤔 우선은`WeatherForecastRoute.createParameters(latitude:longitude:)`로 프로젝트에 필요한 queryItems를 생성할 수 있도록 구현했다.

#### 재사용성
다른 프로젝트에서 해당 네트워크 타입을 그대로 활용할 수 있도록 재사용성을 높이고자 했다. 이를 위해 어떤 프로젝트에도 국한되지 않는 부분과 이번 프로젝트에만 적용되는 부분을 분리하는 것에 초점을 맞췄다.
- 실제 URLSession으로 통신을 하는 기능은 NetworkModule에 구현했다. URLRequest만 전달해주면 어떤 요청으로든 통신할 수 있어 재사용이 가능하다.
- 네트워크 통신은 전반적으로 관리하는 NetworkManager도 재사용할 수 있는 타입이다. 통신에 필요한 정보를 외부에서 받아 Request를 생성하고 이를 Networkable 타입에게 전달해 통신을 맡기는 역할을 담당한다. 의존성 주입을 통해 NetworkModule을 지니고 있다.
- URLRequestTask는 queryItems, 헤더, 바디 parameters의 여부에 따라 적절한 URLRequest를 만들어 리턴하는 타입이다. 이 역시 재사용이 가능하지만 현재 queryItems로만 URLRequest 생성하는 로직밖에 없다. 다른 종류의 URLRequest 생성 로직도 추가할 수 있도록 enum 타입으로 구현되어있다.

#### SOLID의 개방폐쇄 원칙
다른 프로젝트에서 해당 네트워크 타입을 가져다 쓸 때 별도의 수정은 필요없도록, 하지만 새로운 기능을 추가할 수 있도록 설계 했다.
- URLRequestTask는 enum으로 구현되어 있으며 case에 URLRequest의 종류를 추가할 수 있다. 분기 처리를 통해 원하는 종류의 URLRequest를 생성할 수 있다. 하지만 기존의 URLRequest 종류는 수정할 필요가 없다. 실제 네트워크 요청의 종류에 맞게 구분되어 있기 때문이다.
- URL의 필수 정보는 Route 프로토콜에서 요구하고 있다. 하지만 실제 프로젝트에서 사용할 타입은 Route를 채택한 WeatherForecastRoute로 프로젝트마다 필요에 따라 기능을 추가할 수 있다.


### API 데이터 중 어느 것을 옵셔널로 둬야할지
OpenWeather API문서에 따라 데이터의 타입을 구현했다. 하지만 네트워크 통신 결과 어떤 데이터는 일부 항목을 제공하지 않을 수도 있음을 확인했다. 
- 만약 데이터 모델의 프로퍼티를 옵셔널이 아닌 값으로 지정했는데 해당 항목의 데이터가 받아지지 않는다면 JSON데이터를 디코딩할 수 없는 문제가 발생한다. 

문제는, API문서에 데이터의 어느 항목이 안 받아질 수 있는지 안내되어 있지 않다는 점이었다. 
- 여러 데이터 테스트해본 결과 공통적으로 특정 항목 몇 개만 비어있는 것을 확인할 수 있었다. 따라서 해당 항목만 옵셔널로 두어 처리를 했다. 
- 만약 추가로 디코딩 문제가 발생한다면 안전하게 모델의 모든 프로퍼티를 옵셔널로 지정해 해결할 수 있을 것 같다.

### 권한(location)이 없을 때 어떻게 처리할지?
기기의 위치는 LocationManager의 location 프로퍼티를 통해 가져온다. 하지만 만약 사용자가 앱에게 권한을 부여하지 않았다면 앱은 기기의 위치를 받아올 수 없게 된다. 이 경우 사용자에게 최종적으로 처리할 수 있는 방법은 크게 두 가지가 있다고 생각했다.

#### 1. 고정된 위치의 날씨
만약 권한이 없어 위치를 가져오지 못한다면 사용자에게 특정한 위치의 날씨를 보여주는 방법이 있다. 
- 아무 지역이나 보여줘도 되지만 이왕이면 사용자 기기의 지역이나 언어 세팅을 참고해 관련된 나라의 수도 날씨를 가져오는 것이 더 뛰어난 사용자 경험을 제공한다고 생각했다.
  - 하지만 날씨 데이터를 받아오기 위해서는 위도와 경도가 필요한데, 기기의 지역이나 언어를 바로 연관된 위도/경도로 변환하는 Swift 내부 기능은 찾지 못 했다. 
  - (추가된 부분) func geocodeAddressString() 해당 함수로 지역명을 통해 위도와 경도를 가져올수 있는 방법이 있으나, 사용자가 내 위치정보를 공유하고 싶지 않다고 했는데 이 어플에서 아이폰에 설정된 기본값에 접근해서 정보를 가져온다는게 맞는건지 의문이 들었다. 또한 openAPI에서 [ISO3166](https://ko.wikipedia.org/wiki/ISO_3166-1) 코드를 통해서도 URL을 만들수있으나 굳이..
  - 그렇다면 차선책으로 딕셔너리에 지역세팅과 위도/경도를 저장해두고 이를 참고할 수 있을 것 같았다. 하지만 모든 나라의 정보를 저장하는 것은 무리가 있다고 생각했고 제한된 나라의 정보만 저장할 경우 나머지에 대한 처리가 모호해진다는 문제가 있었다.
- 기기의 위치가 아닌 특정 위치의 날씨 정보를 제공하는 경우 사용자가 이를 오류라고 인식할 위험성이 있다고 판단했다. 따라서 사용자에게 권한이 허용되지 않았다는 안내를 할 필요가 있다고 생각했다. 이 경우 LocationManager가 ViewController에게 권한이 허용되었는지의 여부도 반환할 필요가 있다고 생각했다.
  - 하지만 예를 들어 ViewController에서 UIAlertController를 보여준다면 이를 ViewController나 ViewController를 참조하는 곳에서 해야 한다. 따라서 이 부분은 컴플리션핸들러나 delegate 패턴을 활용해볼 수 있을 것 같다.

#### 2. 빈화면
만약 권한이 없어 기기의 위치를 모른다면 아무 정보도 제공해주지 않는 것도 합리적이라고 생각했다. 1번의 경우보다는 덜 하지만 빈화면이 나올 때도 사용자가 오류라고 인식할 위험이 있어 이번에도 역시 권한이 없어서 데이터를 가져오지 못 했다는 알림 문구를 띄우는 것도 좋다고 생각했다.

### Localized Error
- 원래 Error와 Localized Error 모두 채택하고 있었는데 Localized Error가 Error를 채택하고 있어 하나만 선택하기로 결정했다.
- Localized Error는 localized 된 에러 메시지를 직접 지정해줘야할 것 같아서 불필요한 프로토콜처럼 보였다.
- 하지만 정작 Error에는 localizedError라는 프로퍼티밖에 없고
- LocalizedError는 errorDescription이라는 프로퍼티에 메시지를 지정해주면 localizedDescription으로 해당 에러를 볼 수 있는 기능이 있어 더 좋아 보였다.
- 실수로 errorDescription을 String 타입으로 구현했더니 의도한대로 작동하지 않아 요구사항대로 String?으로 변경해주었다.
  - errorDescription의 경우 LocalizedErorr의 인스턴스 프로퍼티로 기본 구현 되어있다. 하지만 errorDescription에 옵셔널을 안붙이면 새로운 연산프로퍼티를 만든거라고 인식을 해서 오류가 안찍히는 현상이 발생되었다.


### iOS 버전에 따른 분기 처리
- 기존에 앱의 배포 타겟을 iOS 14.3 버전으로 했었는데 [iOS의 사용 현황](https://developer.apple.com/kr/support/app-store/#:~:text=85%25%EC%9D%98%20%EA%B8%B0%EA%B8%B0%EA%B0%80%20iOS%C2%A014%EB%A5%BC%20%EC%82%AC%EC%9A%A9%ED%95%98%EA%B3%A0%20%EC%9E%88%EC%8A%B5%EB%8B%88%EB%8B%A4.)을 확인해보니 iOS 14.를 사용하는 기기는 약 85%밖에 되지 않음을 확인했다. 문서에 따르면 기기의 93%가 사용하는 iOS 13.0이 적절해보여 배포 타겟을 iOS 13으로 변경했다.
- 하지만 CLLocationManager의 authorizationStatus 프로퍼티는 iOS 14.0부터 사용할 수 있는 기능이었기 때문에 버전을 13.0으로 낮추려면 구기능인 [authorizationStatus()](https://developer.apple.com/documentation/corelocation/cllocationmanager/1423523-authorizationstatus) 타입 메서드를 사용해야 했다. Deprecated된 구기능은 오류가 발생할 수도 있고 이후 iOS에서 더이상 지원하지 않을 수도 있기 때문에 버전 별로 분기 처리를 해주었다.
  ```swift
  if #available(iOS 14.0, *) {
      status = manager.authorizationStatus
  } else {
      status = CLLocationManager.authorizationStatus()
  }
  ```
