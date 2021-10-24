# 날씨 정보 README.md

#### 프로젝트 기간: 2021.09.27 - 2021.10.22
#### 프로젝트 팀원: [Geon](https://github.com/jgkim1008), [Joey](https://github.com/joey-ful)
#### 실행 방법
APIKey.plist 파일을 생성해 아래 경로에 위치
APIKey.plist에는 키가 `APIKey` 값이 [OpenWeather](https://openweathermap.org/appid)의 APIKey]인 항목이 저장
```
/WeatherForecast/WeatherForecast/APIKey.plist
```

## I. 앱 기능 소개

<p float="left">
    <img src="https://user-images.githubusercontent.com/52707151/138420201-93f8fefd-f85c-451c-9e4f-5c8c447b4bb5.gif"/>
    <img src="https://user-images.githubusercontent.com/52707151/138421444-7e2d504e-5986-4205-8864-57727ae2d4cb.gif"/>
    <img src="https://user-images.githubusercontent.com/52707151/138422414-bf1e83f6-a0ed-4727-be8b-b09815af90e6.gif"/>
</p>

|1번 gif|2번 gif|3번 gif|
|----|----|----|
|• 기기는 현재 위치의 날씨를 받아오지만 위치를 변경할 수도 있다.<br>• 새로고침하여 날씨를 업데이트 할 수 있다.<br>• `현재 위치로 재설정`을 누르면 현재 위치의 날씨를 받아온다.|• 버튼을 통해 위치를 지정하거나 현재 위치로 세팅할 수 있으며 버튼은 두 가지 종류가 있다: <br> &nbsp; &nbsp; - 주소가 없으면 `위치변경`<br> &nbsp; &nbsp; - 주소가 있으면 `위치설정`<br>|• 앱 세팅에서 언어를 변경하면 지역화된 언어, 날짜 포맷, 온도 표기법으로 보여준다. <br> • 현재는 한국만 text에 대한 Localization이 적용되어 있다. |


## II. 설계/구조
### UML

![Weather_Forecast drawio (3)](https://user-images.githubusercontent.com/52592748/138574682-031b1271-aefe-4741-bd36-3e1d96dba90d.png)

### 타입별 역할

#### View관련
|View/Controller 타입|역할|
|---|---|
|WeatherForecastViewController|LocationManager를 사용하여 받은 현재위치를 포함하여, 가공된 위치날씨 정보를 보여준다.|
|WeatherHeaderView|CollectionView의 HeaderView에 style, contents를 가공한다.|
|WeatherForecastCustomCell|CollecionView의 Cell의 style, contents를 가공한다.|
|UIAlertController extension|주소의 유무에 따라 보여주는 AlertController를 가공한다.<br>위치 변경시 ViewController에게 Notification으로 새로운 위치 데이터 전달|

#### Utilities

|Util 타입|역할|
|---|---|
|LocationManager|CLLocationManager를 사용하여 현재 위치(위도, 경도)를 가져온다.<br>reverseGeocoding으로 위치의 주소를 가져온다.|
|WeatherForecastRoute|프로젝트의 URL 및 URI에 대한 정보를 가지고 있으며 입력받은 정보를 URLRequest용 parameter 형식으로 변환한다.|
|NetworkManager|URLRequest를 생성하는데 필요한 정보를 URLRequestTask에 전달해 URLRequest를 생성 후 NetworkModule에게 이를 전달한다.|
|URLRequestTask|URLReqeust를 생성한다.|
|NetworkModule|URLRequest를 통해 네트워크 통신을 진행 후 데이터를 completion에 전달한다.|
|ImageManager|URL를 통해 네트워크 통신을 진행 후 데이터를 UIImage로 변환해 completion에 전달한다.<br>이미지를 URLCache에 캐싱한다.|
|Decodable extension|Data타입의 데이터를 지정한 형식으로 파싱한다.|
|TemperatureManager|Kelvin 온도 형식을 Locale.current의 온도 형식으로 변환한다.|
|DateFormatter extension|UNIX 형식 날짜를 Locale.current의 날짜 형식으로 변환한다.|

#### Model
|Model 타입|역할|
|---|---|
|CurrentWeather|현재 날씨 데이터 모델|
|CommonWeather|현재 날씨와 5일치 날씨 데이터 모델에어 공용으로 사용하는 데이터 모델 모음|
|FiveDayWeather|5일치 날씨 데이터 모델. 3시간 단위의 날씨 데이터가 List 타입 배열에 저장된다.|
|WeatherHeader|컬렉션뷰의 헤더에 필요한 데이터 모델|
|Coordinates|위도/경도를 전달할 때 필요한 데이터 모델|
|Address|reverseGeocoding으로 변환된 주소를 전달할 때 필요한 데이터 모델|




















## III. 트러블 슈팅

### 중복 요청 처리

- 문제상황1:
    - 중복으로 네트워크 요청을 보내는 경우 중복으로 처리하지 않도록 방어를 하였으나 서로 다른 Requset임에도 불구하고 직전의 URLSessionDataTask를 무조건 cancel하는 문제가 발생했다.
    ```swift
    let dataTask: URLSessionDataTask?
    dataTask?.cancel()
    dataTask = nil
    
    dataTask = URLSession.shared.dataTask(with: request) {}
    dataTask.resume()
    ```
- 해결 방법1: URLSessionDataTask의 currentRequest 비교 로직
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
- 문제상황2:
    - 같은 Request가 연속적으로 요청되지 않으면 중복 요청임에도 방어가 되지 않음을 확인할 수 있었다. 예를 들어 요청이 A, B, A 순으로 올 경우 두 번의 A 요청이 모두 통신되는 문제가 발생한다.
- 해결 방법2: URLSessionTask - originalRequset, [URLSessionDataTask]
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
- 문제사항3:
    - dataTask가 오리지널 request를 비교, 하지만 동시에 dataTask배열에 같은index를 삭제하려다보니 삭제된 index를 다시 삭제 하는 경우 out of range 에러가 발생


- 해결 방법3: 배열의 갯수 확인한후 cancel 로직 추가, 정상적으로 dataTask는 배열에서 삭제하도록 로직 추가
    - dataTask 배열의 갯수를 통해 dataTask배열의 갯수가 접근하고자하는 index 보다 클경우에만 삭제하도록 로직변경
    - NetworkModule의 runDataTaks(request:completionHandler) 메서드는 내부적으로 비동기로 동작하기에 error 및 정상적인 response이면 배열에서 삭제하도록 로직 추가 
    ```
    dataTask.enumerated().forEach { (index, task) in
        if let originalRequest = task.originalRequest,
              originalRequest == request {
            task.cancel()
            if dataTask.count > index {
                dataTask.remove(at: index)
            }
        }
    }
    ```

- 문제사항4:
    - 연속으로 dataTask를 취소할떄 cancelled 에러가 발생
- 해결 방법4:
    - 구현된 로직상 중복되는 dataTask는 취소되게 구현하였으므로 dataTask가 cancelled되는것은 오류가 아니다. 
    - error의 description중 cancelled는 오류가 아니라고 로직변경
    ```
    DispatchQueue.global().async {
        self.downloadDataGroup.enter()
        self.networkManager.request(with: route,
                            queryItems: queryItems,
                            httpMethod: .get,
                            requestType: .requestWithQueryItems) { result in
    switch result {
    case .success(let data):
        self.extract(data: data, period: route)
    case .failure(let networkError):
        if networkError.localizedDescription != "cancelled" {
        assertionFailure(networkError.localizedDescription)
        }
    ```

### 2. 하나의 메서드에서 여러 종류의 타입을 파싱
현재 앱에서 사용하는 날씨 데이터는 `CurrentWeather`와 `FiveDayWeather`라는 두 가지 모델이 존재한다.
두 모델을 하나의 제네릭 메서드가 파싱하는 방향으로 구현해 재사용성을 높이고 중복 코드를 줄이고자 했다.

#### 문제상황 1 - 네트워크 요청을 하는 곳에서 파싱한 데이터 전달, 타입 추상화
- 네트워크 통신을 해 데이터를 받아오는 NetworkModule 타입에서 파싱까지 한 번에 진행하도록 구현했다.
- 그리고 NetworkModule의 통신 메서드를 어떤 타입이든 파싱할 수 있도록 제네릭 메서드로 구현했다.
  - NetworkModule의 메서드를 제네릭으로 구현하면서 NetworkManager의 메서드도 제네릭 메서드로 구현했다.
  - `CurrentWeather`와 `FiveDayWeather`를 `WeatherModel` 타입으로 추상화해주었다.
- 뷰컨트롤러에서 `getWeatherData<WeatherModel>(type:of:route:)`라는 메서드로 두 데이터를 모두 받을 수 있도록 했다. 로직 구현까지는 문제없이 잘 빌드되었다.

🚨 하지만 뷰컨트롤러에서 `getWeatherData<WeatherModel>(type:of:route:)`를 사용하는 순간 다음과 같은 에러가 발생했다.
![image](https://user-images.githubusercontent.com/52592748/136516097-78e30c53-0ea4-40cb-a7c5-05b2cc3698e5.png)

<details>
<summary> <b> 문제상황 1 코드 </b>  </summary>
<div markdown="1">
  
- `getWeatherData<WeatherModel>(type:of:route:)` 호출부
```swift
// WeatherForecastViewController.swift
protocol WeatherModel: Decodable {}

class WeatherForecastViewController: UIViewController {
    //...
    private func initData() {
        //...
        
        getWeatherData(type: CurrentWeather, of: location, route: .current)
        getWeatherData(type: FiveDayWeather, of: location, route: .fiveDay)
    }
    //...
}
```

- `getWeatherData(type:of:route:)`
  
```swift
// WeatherForecastViewController.swift
private func getWeatherData<WeatherModel: Decodable>(type: WeatherModel,
                                                         of location: CLLocation,
                                                         route: WeatherForecastRoute) {

    networkManager.request(//...
                          ) { (result: Result<WeatherModel, Error>) in
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

- NetworkModule의 메서드

```swift
// NetworkModule.swift
mutating func runDataTask<T: Decodable>(type: T, request: URLRequest,
                          completionHandler: @escaping (Result<T, Error>) -> Void) {
    //...

    let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
        //...

        DispatchQueue.main.async {
            let result = data.parse(to: T.self)
            switch result {
            case .success(let parsed):
                completionHandler(.success(parsed))
            case .failure(let error):
                completionHandler(.failure(error))
            }

        }
    //...
}

```

- NetworkManager의 메서드
```swift
// NetworkManager.swift
mutating func request<T: Decodable>(//...
                                        completionHandler: @escaping (Result<T, Error>) -> Void) {
    //...
    networkable.runDataTask(type: type, request: urlRequest, completionHandler: completionHandler)
}
```

</div>
</details>
<br>

- WeatherModel이 구체타입이 아니기 때문에 발생하는 문제라 생각했다. 하지만 에러가 발생하지 않는 해결법을 찾지 못해 Opaque Type을 공부해볼 계획이다.
- 다른 해결법을 찾기 위해 이번엔 파싱 로직을 네트워킹 타입에서 뷰컨트롤러로 이동해보았다.

#### 문제상황 2 - 중첩 switch문
뷰컨트롤러의 `extract(data:period:)`에서 어떤 모델 타입이든 관계없이 데이터를 파싱하고 파싱한 결과를 처리하도록 구현하고자 했다. 하지만 파싱 작업에는 두 번의 분기처리가 필요했다:
1. switch문을 사용해 파싱할 타입을 찾아야 했다.
2. 파싱한 결과가 `Result`타입으로 반환되기 때문에 switch문 분기처리가 한 번 더 필요했다.

🚨 결과적으로 중첩 switch문 때문에 가독성이 떨어지는 단점이 생겼다.

<details>
<summary> <b> 문제상황 2 코드 </b>  </summary>
<div markdown="1">

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
</div>
</details>
<br>

#### 해결방법 1 - 하나의 타입으로 추상화, 함수 분리
문제를 해결하기 위해 두 가지를 시도했다:
1. 데이터모델들(`CurrentWeather`와 `FiveDayWeahter`)를 `WeatherModel`이라는 하나의 Protocol 타입으로 추상화했다. 
2. `extract(data:period:)` 로직을 `filter(parsedData)`에 분리했다:
  - `extract(data:period:)` - 어떤 타입으로 파싱할지 분기처리 후 파싱
  - `filter(parsedData)` -  디코딩한 결과를 `Result<WeatherModel, ParsingError>`타입 매개변수로 전달받아 분기처리.

🚨 하지만 `Result<CurrentWeather, ParsingError>`타입을 `Result<WeatherModel, ParsingError>` 타입에 담을 수 없다는 에러가 발생했다.
![image](https://user-images.githubusercontent.com/52592748/136514211-9fed3443-380c-423f-beca-3fd68926ec56.png)
- Result에는 구체타입을 넣어줘야했기 때문에 추상타입인 WeatherModel로 받을 수 없었던 것이었다.

<details>
<summary> <b> 해결방법 1 코드 </b>  </summary>
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

#### 해결방법 2 - 제네릭 메서드
Result의 타입에 제네릭 타입을 넣어 해결하기로 했다. 그리고 해당 제네릭 타입이 WeatherModel을 채택하도록 하여 CurrentWeather와 FiveDayWeather 두 타입을 모두 하나의 매개변수 타입으로 받을 수 있도록 했다.

<details>
<summary> <b> 해결방법 2 코드 </b>  </summary>
<div markdown="1">

```swift
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

func filter<T: WeatherModel>(parsedData: Result<T, ParsingError>) {
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



### DispatchGroup
#### 문제상항
- `현재날씨`와 `5일치날씨` 데이터를 서버에서 받아와 하나의 컬렉션뷰에 띄워야 했다.
- 하지만 둘의 네트워크 통신이 모두 끝나는 시점을 알 수 없어 `5일치날씨` 데이터의 다운이 끝난 직후 컬렉션뷰를 업데이트 해주었다.

🚨 하지만 간혹 `현재날씨`가 컬렉션뷰에 반영되지 않는 문제가 발생하였다.
- `현재날씨`와 `5일치날씨`가 각각 다운된 후마다 컬렉션뷰를 업데이트 해주는 방법으로 모든 데이터가 반영되게 할 수 있었지만 매번 화면을 보여줄 때마다 뷰를 두 번씩 업데이트하는 것은 비효율적이라고 판단했다.


#### 해결방법
* 비동기 작업이 **모두 완료된 시점**을 알기 위해 DispathGroup을 적용했다.
    * `현재날씨`와 `5일치날씨` 데이터를 서버에 요청할때 그룹에 `enter()`를 하고 요청 후 파싱이 완료될때 `leave()`를 해주었다. 
    - enter한 작업들이 모두 leave한 시점을 알리는 `notifiy()`를 통해 모든 데이터의 다운로드가 끝난 시점에 컬렉션뷰를 업데이트하도록 했다.


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

### 권한(location)이 없을 때 처리
기기의 위치는 LocationManager의 location 프로퍼티를 통해 가져온다. 하지만 만약 사용자가 앱에게 권한을 부여하지 않았다면 앱은 기기의 위치를 받아올 수 없게 된다. 이 경우 사용자에게 최종적으로 처리할 수 있는 방법은 크게 두 가지가 있다고 생각했다.

#### 1. 고정된 위치의 날씨
만약 권한이 없어 위치를 가져오지 못한다면 사용자에게 특정한 위치의 날씨를 보여주는 방법이 있다. 
- 아무 지역의 날씨 정보를 제공할 수도 있지만 되지만 이왕이면 사용자 기기의 지역/언어 세팅에 관련된 지역의 날씨를 가져오는 것이 더 뛰어난 사용자 경험을 제공한다고 생각했다.
  - 이를 위해서는 지역명을 통해 위도/경도를 가져오는 `geocodeAddressString()`를 활용해볼 수 있지 않을까 생각했다. 아니면 날씨 정보 openAPI에서 [ISO3166](https://ko.wikipedia.org/wiki/ISO_3166-1) 날씨 정보고 제공하고 있어 `Locale.current.regionCode`로 데이터를 받아올 수도 있다고 생각했다.
  - 하지만 사용자가 위치정보를 공유하고 싶지 않다고 했음에도 기기 설정에 접근해 정보를 가져오는 것이 옳은지 의문이 들었다.
  - 또한, 기기의 위치가 아닌 특정 위치의 날씨 정보를 제공하는 경우 사용자가 이를 오류라고 인식할 위험성도 있다고 판단했다. 

따라서 권한이 없는 경우 사용자에게 권한이 허용되지 않았다는 안내를 할 필요가 있다고 생각했다.

#### 2. 빈화면
만약 권한이 없어 기기의 위치를 모른다면 아무 정보도 제공해주지 않는 것도 합리적이라고 생각했다. 이 역시 사용자가 오류라고 인식할 위험이 있지만, 위치변경 버튼으로 직접 위치를 지정할 수 있도록 한다면 따로 안내를 하지 않아도 괜찮다고 생각했다.


### Localized Error
- 원래 Error와 Localized Error 모두 채택하고 있었는데 Localized Error가 Error를 채택하고 있어 하나만 선택하기로 결정했다.
- Localized Error는 localized 된 에러 메시지를 직접 지정해줘야할 것 같아서 불필요한 프로토콜처럼 보였다.
- 하지만 정작 Error에는 localizedError라는 프로퍼티밖에 없고
- LocalizedError는 errorDescription이라는 프로퍼티에 메시지를 지정해주면 localizedDescription으로 해당 에러를 볼 수 있는 기능이 있어 더 좋아 보였다.
- 실수로 errorDescription을 String 타입으로 구현했더니 의도한대로 작동하지 않아 요구사항대로 String?으로 변경해주었다.
  - errorDescription의 경우 LocalizedErorr의 인스턴스 프로퍼티로 기본 구현 되어있다. 하지만 errorDescription에 옵셔널을 안붙이면 새로운 연산프로퍼티를 만든거라고 인식을 해서 오류가 안찍히는 현상이 발생되었다.

### APIKey의 저장
API Key는 코드 내에 하드코딩으로 두는 것보다는 권한이 있는 사람들만 볼 수 있는 것이 좋다고 판단했다.
- 따라서 API Key를 새로운 plist 파일에 저장하고 이 파일을 .gitignore에 추가함으로써 개발시 보안을 유지하고자 했다.
- 물론 보안이 완벽하지는 않다고 생각했다. 앱 배포시 코드가 바이너리 형태로 바뀌어도 리버스 엔지니어링을 통해 컴파일된 파일도 읽을수 있기 때문이다. 하지만 API Key는 비교적 간단하면서도 노출되었을 때 치명적인 정보는 아니라고 판단해 암호화 저장소인 Key Chain보다는 plist 파일을 활용해보았다.

#### API Key 에러처리
API Key를 plist에 저장하게되면서 이를 가져올 때 다음의 경우에 옵셔널 바인딩을 해줄 필요가 있었고 실패시 에러 처리 또한 중요하다고 생각했다:
- plist 파일이 없는 경우
- plist 파일에서 API Key를 가져오는데 실패한 경우

API Key가 없으면 날씨 데이터를 가져올 수 없는데 이 때 사용자에게 알릴 필요가 없다고 판단했다.
- APIKey가 없으면 날씨 데이터가 받아지지 않고 이때 사용자는 빈화면을 보게 되도록 처리했다.
- 이때 assertionFailure()로 개발자에게만 관련 에러가 출력되도록 했다.

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
  
### 주소 여부에 따라 바뀌는 버튼
주소의 여부에 따라 위치변경이 다른 알럿을 띄우도록 했다. 
- 이를 위해 버튼을 두 개 만들어두고 어느 버튼을 보여줄지 고르는 방식도 있지만 액션만 다른 버튼인데 굳이 여러개 만들 필요가 없다고 판단했다. 무엇보다 경우의 수가 많아짐에 따라 버튼도 많아지는 것을 원치 않았다.
- 따라서 버튼은 특정 클로저를 액션으로 취하고 이 클로저에는 매번 코드 블록을 전달해 버튼을 재사용할 수 있도록 했다.


### 위치를 변경할 때마다의 처리
#### 구현 의도
1. 사용자가 **지정한 위치의 날씨 정보**를 받아볼 수 있도록 구현하고자 했다.
- 다음과 같은 알럿에 원하는 위치의 위도와 경도를 입력하여 `변경`을 누르면 지정한 위치를, `현재 위치로 재설정`을 누르면 현재 기기의 위치를 선택하도록 했다.
![image](https://user-images.githubusercontent.com/52592748/138475000-9ef10592-7e74-4f86-ab8b-97dbac87e0a9.png)
2. 사용자가 위치를 변경 후 **새로고침**을 하면 **가장 최근 위치의 날씨 정보**를 업데이트하도록 했다.
  - 사용자가 권한을 허용하지 않으면 빈 화면이 뜨며 권한을 허용해두면 현재 위치 날씨 정보가 제공된다.
  - 하지만 만약 사용자가 위치를 직접 지정하면 지정한 위치의 날씨 정보가 제공된다.
  - 근데 새로고침했을 경우 다시 빈 화면이나 현재 기기위치의 날씨 정보가 제공된다면 사용자 입장에서는 버그나 불편함으로 인식될 수 있다고 판단했다.
  - 따라서 새로고침시 가장 최근에 지정한 위치의 날씨 정보를 가져오도록 했다. 
3. 사용자가 **실수로 위도/경도를 잘못 입력했을 때** 가장 최근에 지정한 위치의 날씨 정보 화면에 머물러 있는 것이 자연스럽다고 판단해 **아무 처리도 하지 않도록** 했다.
4. 권한이 없는데 현재 위치의 날씨 정보를 받아오려고 한다면 빈 화면이 뜨도록 했다.

#### 구현 방법
- 가장 최근에 지정된 위치를 기억해야할 필요가 있다고 판단해 WeatherForecastViewController가 위도와 경도를 프로퍼티로 들고 있게 했다.
- 사용자가 입력한 위도/경도를 뷰컨트롤러에게 전달할 수 있도록 알럿의 UIAlertAction의 handler에서 NotificationCenter를 활용해 userInfo에 위도/경도를 전달했다.
  - `현재 위치로 재설정`하는 경우 위도/경도를 전달할 필요 없이 LocationManager로 현재 위치를 받으면 되기 때문에 userInfo에는 nil을 전달해 의도를 나타냈다.
  - LocationManager는 권한이 없는 경우 현재 위치를 반환하지 않기 때문에 `현재 위치로 재설정` 버튼을 눌러도 권한이 없다면 현재 위치 날씨 정보를 보여주지 않는다.
- 위도/경도를 잘못 입력한 경우에는 마치 cancel 버튼을 누른 것처럼 아무 것도 하지 않도록 UIAlertAction의 handler에서 바로 return을 해주었다.


### Strong Reference Cycle
UIAlertController에 UITextField를 사용하고 있고 이를 UIAlertAction이 참조할 필요가 있었다. 따라서 액션은 알럿을 참조하고 알럿은 액션을 들고있는 순환 참조 관계가 발생했다.
- 따라서 액션이 알럿을 참조할 때 알럿을 캡처리스트에 추가해 싸이클을 깨주었다.
    ```swift
    let action = UIAlertAction(title: title, style: .default) { [weak alert] _ in
        alert?.textFields?[0].text
    }
    ```
- 뷰컨트롤러가 컬렉션뷰를 프로퍼티로 갖고 있는데 `CellRegistration`과 `SupplementaryRegistration`의 handler에서 self를 참조하고 있다. 이 역시 강한 참조 싸이클이 발생해 weak self를 캡처리스트에 추가해 싸이클을 깨주었다.

### 위도/경도를 숫자만 받게 제한
위도/경도 입력을 받는 UITextField의 키보드 타입을 숫자패드로 하여 사용자에게 숫자만 입력받는다는 의도를 나타내고자 했다. 하지만 위도/경도는 Double타입이며 음수값도 가능하기에 `.`과 `-` 기호를 받아야해서 numPad, decimalPad 그리고 phonePad 모두 사용할 수 없었다.
대신 키보드 타입을 numbersAndPunctuation으로 지정해주었다.
- numbersAndPunctuation으로 하면 숫자 및 기호 키보드가 올라오기에 사용자가 정수를 입력해야됩니다 라는 개발자의 의도를 전달하고 싶었습니다.
    - 그래서 결국 Double() 옵셔널바인딩으로 해결
- 잘못된 위도/경도 지정시 동작하지 않게 구현을 하고 싶었다.그래서 cancel과 동일하게 처리하려고 guard 문을 통하여 Doubel로 타입이 변환되지 않을떄는 빠른 종료 되게 로직 변경을 하였다.


### URLCache
- URLCache를 활요하기 위해 URLSession.shared 대신 커스텀한 URLSession을 구현했다.
- URLCache의 용량을 키우고 URLSessionConfiguration의 캐시 규약을 `.returnCacheDataElseLoad`로 지정해 캐시된 데이터를 사용하도록 했다. 
    ```swift
    private let customURLSession: URLSession = {
        URLCache.shared.memoryCapacity = 512 * 1024 * 1024
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
    ```
- 그리고 customURLSession으로 네트워크 통신을 진행했다.
- 별도로 캐싱하는 작업을 하지 않았기에 캐싱이 잘 되는지 확인할 필요가 있었다. 네트워크 통신의 completionHandler에 breakpoint를 걸어 사용되고 있는 캐시 용량을 `currentMemoryUsage`로 확인해보았고 결과적으로 캐싱이 잘 됨을 확인할 수 있었다.
    ```
    po URLCache.shared.currentMemoryUsage
    ```

### 지역화
날씨 정보를 지역화를 위해 날짜 포맷, 온도 포맷 그리고 언어를 현재 Locale에 맞게 지정해주었다.
#### 날짜 포맷
현재 Locale에 맞춰 날짜 형식을 지정하도록 했다. dateStyle과 timeStyle을 골라 제공되는 포맷 형식들을 사용해도 되지만 보다 커스텀한 날짜 형식이 필요했다.
- Dateformatter의 dateFormat 프로퍼티나 setLocalizedDateFormatFromTemplate()을 사용해 보다 커스텀한 Locale.current 형식을 취할 수 있었다.

#### 온도 포맷
날씨정보 openAPI에서 제공하는 default 온도 형식은 kelvin이다. 그리고 queryItem으로 온도 형식을 지정해서 데이터를 받아올 수 있다.
- 하지만 어차피 받아온 온도를 symbol도 추가하고 반올림도 해주는 처리작업이 필요했다.
- 따라서 그냥 kelvin 온도를 받아 내부적으로 변환, symbol추가, 반올림을 한번에 처리하기로 했다.
  - `UnitTemperature.celsius.conver.value(fromBaseUnitValue:)`와 같은 내장 변환 메서드를 활용했다.
- 이때 어떤 온도 형식을 사용할지는 `Locale.current.usesMetricSystem`을 보고 판단했다.
    ```swift
    final class TemperatureManager: Dimension {

        /// 온도를 변환 후 fractionalCount 자리까지 반올림해주는 메서드
        static func convert(kelvinValue: Double, fractionalCount: Int) -> String {
            let tempData: Double
            let symbol: String

            if Locale.current.usesMetricSystem == true {
                tempData = UnitTemperature.celsius.converter.value(fromBaseUnitValue: kelvinValue)
                symbol = "°C"
            } else {
                tempData = UnitTemperature.fahrenheit.converter.value(fromBaseUnitValue: kelvinValue)
                symbol = "°F"
            }

            let digitShifter = NSDecimalNumber(decimal: pow(10, fractionalCount)).doubleValue
            let rounded = round(tempData * digitShifter) / digitShifter

            return rounded.description + symbol
        }
    }
    ```

#### 번역
- Strings 파일을 만들어 시스템 언어와 번역하고 싶은 언어를 키-값 형태로 저장해주었다.
- 문자열이 자동으로 현재 Locale에 맞춰 번역되도록 `NSLocalizedString(번역할 문자열, comment: "")`를 활용했다.


### 지연로딩
컬렉션뷰의 모든 cell의 데이터를 한번에 로딩하는 것보다 당장 필요한 셀의 정보만 다운받는 방식의 성능이 더 좋다. 그리고 cell이 재사용될 때마다 그에 맞는 데이터로 교체해주면 된다. 하지만 만약 cell마다 이미지를 다운받아와야 한다면 해당 작업은 비동기라 몇 가지 문제가 발생할 수 있다. 
- 만약 이미지가 다운되기 전에 cell을 재사용하는 경우 이전 이미지가 나타났다가 새 이미지로 바뀌는 깜빡임 현상이 발생할 수 있다. 
- 만약 새 이미지의 다운로드가 이전 이미지의 다운로드보다 더 빠르다면 셀에는 최종적으로 이전 이미지가 표시돼 셀과 이미지의 미스매칭이 발생할 수 있다.

이 문제를 해결하기 위한 세 가지 방법을 비교 후 3번 방법으로 구현했다.
1. cell의 indexPath를 캡쳐한후 다운로드가 완료된 시점에 cell의 indexPath와 비교하는 방법이 있다. 
    - 하지만 컬렉션뷰는 셀의 prefetching을 지원하며 iOS15 tableView에도 적용되어 더이상 indexPath의 비교는 불가능해졌다.
    ```swift
    self.imageManager.loadImage(with: currentImageURL) { result in
        if indexPath == tableView.indexPath(of: self) { // self는 셀
            // 이미지 로드
        }
    }   
    ```
2. URLSessionDataTask를 cell에 전달하여 cell이 재사용될때 dataTask를 cancel시키는 방법이 있다. 완료되지 않은 기존 dataTask를 무조건 취소하기 때문에 셀에 이전 이미지가 로드될 가능성이 사라지게 된다.
    - 하지만 cell과 dataTask간의 의존관계가 생겼다.
    ```swift
    dataTask.cancel()
    dataTask = nil
    self.imageManager.loadImage(with: currentImageURL) { result in
        // 이미지 로드
    }   
    ```
3. 이미지의 고유한 정보를 cell의 프로퍼티에 저장하고 해당 값을 비교하는 방법이 있다. 이미지의 고유한 정보는 아이콘의 id나 이미지의 URL 등을 생각해볼 수 있다.
    - 비동기 작업 전에 캡처된 값과 후의 값을 비교하는 indexPath 비교 방식과 매우 흡사하다.
    ```swift
    cell.urlString = currentImageURL // 이미지의 고유한 정보를 cell에 저장
    self.imageManager.loadImage(with: currentImageURL) { result in
        if currentImageURL == cell.urlString { // 캡처된 값과 다운완료시 값을 비교
            // 이미지 로드
        }
    }   
    ```

### SceneDelegate, 스토리보드 어떻게 지웠는지
- 코드로만 UI를 구현하기 위해 불필요한 스토리보드를 제거해주었다.
    1. 타겟 프로젝트 > General > Deployment Info에서 Main Interface 이름을 제거
    2. Info.plist > Scene Configuration > Application Session Role > Item - (Default Configuration) 에서 Storyboard Name 란을 제거
- 그리고 앱의 첫 스크린을 지정해주기 위해 SceneDelegate에서 윈도우의 rootViewController에 첫 화면이 될 뷰컨트롤러의 인스턴스를 지정해주었다.
    - makeKeyAndVisible()을 실행해 해당 윈도우가 맨 앞에 보이도록 하고 키보드 입력 등을 받도록 했다.
    - iOS12까지는 App Delegate에서 Process LifeCycle과 UI Lifecycle 모두에 관여했으나 iOS13부터는 멀티태스킹을 위하여 Scene Delegate이 UI Lifecycle을 담당하게 바뀌었다.


## V. 학습한 내용
### UICollectionView
- DiffableDataSource를 적용해보았으나 데이터의 생성은 발생해도 수정은 일어나지 않아 DiffableDataSource의 이점을 활용할 수 없었다. 데이터의 수정이 발생하거나 SearchBar를 사용하는 등의 경우가 아니라면 굳이 DiffableDataSource를 사용할 필요가 없다고 판단했다.
- 리스트 형태의 컬렉션뷰를 만들기 위해 ListConfiguration을 사용했다. 하지만 iOS14이후부터 지원하는 기능이라 FlowLayout으로도 리스트를 만들어보면 좋겠다고 생각했다. 다만 FlowLayout의 경우 셀을 구분해주는 divider/separator가 없어 커스텀하게 만들어줘야하는 차이가 있다. UIView로 직접 구성해주거나 DecorativeView등을 활용해볼 수 있을 것 같다.

### memberwise init()
* 구조체에 memberwise init()을 제외한 init()을 추가 구현할경우 memberwise init()을 다시 정의하지 않는 한 사용할 수 없다. 
* 하지만 extension에 커스텀 init()을 구현해준다면 구조체의 memberwise init()을 별도로 정의하지 않아도 사용할 수 있다.

### Hashable
* 해시 테이블이란 자료를 키-값으로 저장해주는 테이블 이다.
* 키를 넣으면 해시테이블에 저장된 값의 주소를 알 수 있고 최종적으로 값을 받아올 수 있다.
* hasher
    - hasher란 키를 받아 해시테이블의 값을 반환하는 역할하며, 특정 키를 넣으면 항상 해당하는 값을 반환 받아야 한다.
    * 이처럼 키끼리 구분이 가능해야해서 Hashable은 Equatable을 채택하고 있고 그 때문에 == 연산자로 키가 같은 상황을 정의해주었다.

### `viewDidLoad()`에서 `super.init()`을 해야하는 이유
자식 클래스가 부모 클래스의 메서드를 오버라이드하고 있는 경우 `super.init()`으로 부모 클래스가 의도한 부분이 온전히 실행되도록 해야한다고 생각한다. 그래야만 부모 클래스에서 필수적으로 해주어야하는 기초 세팅을 마무리해 자식 클래스에서 버그나 오작동 없이 실행할 수 있다고 말할 수 있을 것 같다.
* 그리고 `viewDidLoad()`의 경우 [`super.init()`](https://developer.apple.com/documentation/appkit/nsviewcontroller/1434476-viewdidload) 을 호출하라고 공식문서에 명시되어 있다.

#### Two Phase Initialization
초기화 전에 프로퍼티 값에 접근하는것을 막아 초기화를 안전하게 할수 있게 하고, 다른 이니셜라이저가 프로퍼티의 값을 실수로 변경하는것을 막기 위해 Swift의 class 초기화 과정은 Two Phase Initialization 과정을 거친다. `viewDidLoad()`를 오버라이딩 하기에, safty-check 2번에 해당되어서 `super.init()`을 수행해야 된다고 생각한다.
스위프트 컴파일러는 2단계 초기화를 오류 없이 처리하기 위해 네 가지 safty-check을 진행한다.
1) 자식클래스의 지정 이니셜라이저는 부모클래스의 이니셜라이저를 호출하기 전에 자신의 프로퍼티를모두 초기화 했는지 확인한다.
2) 자식 클래스의 지정 이니셜라이저는 상속받은 프로퍼티에 값을 할당하기 전에 반드시 부모클래스의 이니셜라이저를 호출해야한다.**
3) 편의 이니셜라이저는 자신의 클래스에 정의한 프로퍼티를 포함하여 그 어떤 프로퍼티라도 값을 할당하기 전에 다른 이니셜라이저(최종적으로는 자신의 클래스의 지정 이니셜라이저)를 호출해야한다.
4) 1단계 초기화를 마치기 전까지는 이니셜라이저는 인스턴스 메서드를 호출할수 없고, 인스턴스 프로퍼티에 값을 읽어들일수도 없다.즉 self에 접근할수 없다.
    * Phase1에서는 클래스에 정의한 각각의 저장 프로퍼티에 초깃값이 할당된다.
    * Phase2에서는 모든 저장 프로퍼티의 초기 상태가 결정되면 2단계로 돌입하여 저장 프로퍼티들을 사용자 정의할 기회를 얻는다.
![2Phase Init](https://camo.githubusercontent.com/d9e6b55710a39899ff98d9b579e47f557cd288bc614779a814772f2402847ee7/68747470733a2f2f692e696d6775722e636f6d2f6a64326e3067592e706e67)

### `assertFailure()`
사용자에게는 보여주지 않고 개발자에게만 보여주고 싶은 에러에 대한 처리가 필요했다.

#### `assertFailure()` vs `preconditionFailure()`
* 공통점은 모두 조건을 통해 앱을 비정상 종료시킬수있다는 점이다.
* 하지만 `assertFailure()` 메서드는 디버깅 모드에서만 동작하는 반면 `preconditionFailure()`는 디버깅과 릴리즈 모드 모두에서 동작하여 앱을 종료시킨다.
해당 프로젝트에서는 사용자에게 에러를 보여주고 싶지 않아 디버깅 모드에서만 작동하는 `assertFailure()`를 선택하였다.

### CLLocationManager에서 위치를 받아오는 방법
[출처 Get current location using Core Location (Tutorial)](https://fluffy.es/current-location/)
#### `requestLocation()`
- 내부적으로 startUpdatingLocation()을 호출 후 여러 위치를 수집해 그 중 desiredAccuracy 프로퍼티에 따른 가장 정확한 것을 delegate에게 전달하며 stopUpdatingLocation()을 호출한다.
- 위치를 1회만 가져오기 때문에 지속적인 위치 서비스가 필요하지 않은 경우에 사용한다.
#### `startUpdatingLocation()`
- 처음으로 수집한 위치를 바로 delegate에게 전달하며 기기가 distanceFilter값 이상 이동할 때마다 업데이트된 위치를 전달한다.
    - 지속적인 위치 추적이 필요한 네비게이션 앱에 적합하다고 생각했다.
- UIBackgroundModes 키 추가를 통해 background에서도 위치 수집을 할 수 있다.
- 다만 requestLocation()이랑 startUpdatingLocation()을 호출하지 않아도 앱의 초기 화면에 위치 기반 날씨 정보를 제공해 의문이 들었다. 기기를 바꾸거나 클린빌드를 해도 마찬가지였다.
- 날씨 앱의 경우 지속적인 위치 변경에 따라 날씨 정보를 제공할 필요는 없다고 생각해 requestLocation()을 사용했다.
    
<p float="right">
    <img src ="https://iosimage.s3.amazonaws.com/2019/45-current-location/requestLocation.png", width = "320">
    <img src ="https://iosimage.s3.amazonaws.com/2019/45-current-location/updateLocation.png", width = "400">
</p>
    - 거리 이동은 custom location 변경하면 되는 것 같은데 업데이트를 안 해줘서 didupdatelocation 에서 노티피케이션 보냈더니 뷰가 아예 안 뜸

### 기기보다 큰 배경 이미지
Device의 orientation이 landscape일 때 이미지가 잘리는 현상을 방지하기 위해 이미지를 큰 사이즈로 교체해주었다. ViewController의 배경을 지정하기 위해 view.backgroundColor에 이미지를 넣어주었는데 이 경우 portrait 모드에서 배경 이미지의 일부분만 배경으로 나오는 문제가 발생했다. 

#### 해결방법
배경을 view.backgroundColor에 지정하는 대신 UIimageView에 넣고 UIImageView를 view에 insert해주었다. 

### 배경 이미지를 기기 orientation에 맞춰 회전
#### 문제상황
가로모드를 지원하기 위해 Info.plist에서 지원하는 orientation에 Landscape 모드를 추가했다.
![image](https://user-images.githubusercontent.com/52592748/138460910-d523cc13-d0c6-4105-a3bb-3b0e0adc681d.png)
하지만 가로모드에서 배경 이미지가 회전하지 않는 문제가 발생했다.

#### 해결방법
viewWillTransition에서 UIImageView의 높이와 너비를 매번 새로 지정해주었다.
```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    view.subviews[0].frame.size = CGSize(width: size.width, height: size.height)
}
```

### Content Hugging Priority defaultLow = 250
horizontal 스택뷰에 라벨과 이미지를 넣었더니 다음과 같이 너비가 ambiguous하다는 오류가 발생했다.
![image](https://user-images.githubusercontent.com/52707151/138459605-4ec965e1-9c27-4554-9644-5e44a0bd6023.png)

StackView의 남은 공간을 채우기 위해 어떤 항목을 늘릴지를 CH 우선순위를 통해 알려줘야 했다.
* 하지만 한 라벨이 늘어나도록 CH 우선순위를 defaultLow로 지정했는데도 동일한 오류가 발행하였다.라벨과 이미지의 CH 우선순위는 default가 defaultLow였기 때문이다.
![image](https://user-images.githubusercontent.com/52707151/138459346-e46639f2-2a92-40b1-9edb-63a0602bbada.png)
- 따라서 늘어나지 않고 intrinsic 사이즈 그대로를 갖게할 라벨의 CH를 defaultHigh로 바꿔주었다.


### 컬렉션뷰 ListConfiguration의 sticky 헤더
UICollectionLayoutListConfiguration의 appearance를 plain이나 sidebarPlain으로 지정하니 헤더가 화면에 고정이 되었다. 반면 나머지(grouped, insetGrouped, sidebar)는 헤더가 sticky하지 않았고 그 중 프로젝트 명세서의 샘플 UI와 가장 비슷한 insetGrouped로 설정하였다.

    
## VI. 궁금증/고민거리/도전할 것

### 오토레이아웃 셀 높이 44
이미지에 height를 40보다 낮거나 같게 제약을 주면 다음과 같은 오류가 발생했다.

```
    "<NSLayoutConstraint:0x600001852800 UIImageView:0x7fcccfd26f80.width == UIImageView:0x7fcccfd26f80.height   (active)>",
    "<NSLayoutConstraint:0x600001852850 UIImageView:0x7fcccfd26f80.width == 40   (active)>",
    "<NSLayoutConstraint:0x600001852990 V:|-(0)-[UIStackView:0x7fcccfd24f70]   (active, names: '|':UIView:0x7fcccfd27420 )>",
    "<NSLayoutConstraint:0x6000018529e0 UIStackView:0x7fcccfd24f70.bottom == UIView:0x7fcccfd27420.bottom   (active)>",
    "<NSLayoutConstraint:0x600001853520 'UISV-alignment' UILabel:0x7fcccfd28290.bottom == UIImageView:0x7fcccfd26f80.bottom   (active)>",
    "<NSLayoutConstraint:0x6000018535c0 'UISV-alignment' UILabel:0x7fcccfd28290.top == UIImageView:0x7fcccfd26f80.top   (active)>",
    "<NSLayoutConstraint:0x6000018533e0 'UISV-canvas-connection' UIStackView:0x7fcccfd24f70.top == UILabel:0x7fcccfd28290.top   (active)>",
    "<NSLayoutConstraint:0x600001853430 'UISV-canvas-connection' V:[UILabel:0x7fcccfd28290]-(0)-|   (active, names: '|':UIStackView:0x7fcccfd24f70 )>",
    "<NSLayoutConstraint:0x600001852d50 'UIView-Encapsulated-Layout-Height' UIView:0x7fcccfd27420.height == 44   (active)>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x600001852800 UIImageView:0x7fcccfd26f80.width == UIImageView:0x7fcccfd26f80.height   (active)>

```

당연히 cell은 self-Sizing을 가지고 있기에 내부 컨텐츠들의 사이즈와 같게 설정이 될거라고 생각했지만, Cell이 Image가 들어갔을때는 셀의 높이가 44가 되었다. 다음 두 가지 방법으로 에러를 해결할 수 있었다.
* 이미지 크기를 44로 지정한다.
* 이미지 높이의 priority를 높게 지정한다.

### WeatherForecastViewController 역할 분리
현재 뷰컨트롤러가 거대해서 NotificationCenter나 delegate 패턴을 활용해 역할 분리를 하면 좋을 것 같다.
- 위치 정보와 날씨 정보를 저장하는 모델 타입
- 컬렉션뷰, 레이아웃, 데이터소스 관련 로직

### `NSLocale currentLocale] failed for NSLocaleCountryCode@` 에러
원인은 파악하지 못했지만 [스택오버플로우](https://stackoverflow.com/questions/58075554/ios-13-simulator-reversegeocodelocation-geoaddressobject-nslocale-currentl)를 참고해 기기의 지역을 다시 세팅하니까 에러가 사라졌다

### 지역별로 이미지 세팅하기
* 해당 부분은 Locale에 따른 imgaeAsset만 추가해주면 된다.
