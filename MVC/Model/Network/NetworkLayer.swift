//
//  NetworkLayer.swift
//  homework4.4
//
//  Created by Eldar on 4/1/23.
//
//Дз:
//Прочитать про async await https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
//Изменить запросы get на async await:
// get-  это когда мы стягиваем, получаем данные с апишки сервера к нему относятся:
//fetch- стягивать, получать, decoder
//findProdutsData- получаем данные по правилу Search( ищем и получаем данные)
//fetchProductsData, searchTakeawaysData - также заменен по методу на async await
//decodeData- также заменен по методу на async await



import UIKit

final class NetworkLayer {
    
    static let shared = NetworkLayer()
    private init() { }
    
    var baseURL = URL(string: "https://dummyjson.com/products")!
    
    func decodeOrderTypeData(_ json: String) -> [OrderTypeModel] {
        var orderTypeModelArray = [OrderTypeModel]()
        let orderTypeData = Data(json.utf8)
        let jsonDecoder = JSONDecoder()
        do { let orderTypeModelData = try jsonDecoder
            .decode([OrderTypeModel].self, from: orderTypeData)
            orderTypeModelArray = orderTypeModelData
        } catch {
            print(error.localizedDescription)
        }
        return orderTypeModelArray
    }
    
    // GET request changed to async
    func fetchProductsData() async throws -> MainProductModel {
        let (data, _) = try await URLSession.shared.data(from: baseURL)
        return await decodeData(data: data)
    }
    
    // find changed to async
    func findProductsData(
        text: String
    ) async throws -> MainProductModel {
        let urlQueryItem = URLQueryItem(name: "q", value: text)
        let request = URLRequest(url: baseURL.appendingPathComponent("search")
            .appending(queryItems: [urlQueryItem]))
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return await decodeData(data: data)
    }
    
    func decodeData <T: Decodable>(data: Data) async -> T  {
        let decoder = JSONDecoder()
        return try! decoder.decode(T.self, from: data)
    }
    
    func postProductsData(
        model: ProductModel, completion: @escaping (Result<Data, Error>
        ) -> Void) {
        var encodedProductModel: Data?
        encodedProductModel = initializeData(product: encodedProductModel)
        guard encodedProductModel != nil else { return }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("add"))
        request.httpMethod = "POST"
        request.httpBody = encodedProductModel
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            print("RESPONSE:\(String(describing: response))")
            guard let data = data else { return }
            completion(.success(data))
        }
        task.resume()
    }
    
    func putProductsData(
        id:Int, model: ProductModel, completion: @escaping (Result<Data, Error>
        ) -> Void) {
        var encodedProductModel: Data?
        encodedProductModel = initializeData(product: encodedProductModel)
        guard encodedProductModel != nil else { return }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("\(id)"))
        request.httpMethod = "PUT"
        request.httpBody = encodedProductModel
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            print("RESPONSE:\(String(describing: response))")
            guard let data = data else { return }
            completion(.success(data))
        }
        task.resume()
    }
    
    func deleteProductsData(
        id: Int, completion: @escaping (Result<Data, Error>
        ) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("\(id)"))
        request.httpMethod = "DELETE"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            print("RESPONSE:\(String(describing: response))")
        }
        task.resume()
    }
    
    func decodeData<T: Decodable>(
        data: Data, completion: @escaping (Result<T, Error>
        ) -> Void) {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(T.self, from: data)
            completion(.success(decodedData))
        } catch {
            completion(.failure(error))
        }
    }
    
    func encodeData<T: Encodable>(
        product: T, completion: @escaping (Result<Data, Error>
        ) -> Void) {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(product)
            completion(.success(encodedData))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func initializeData<T: Encodable>(product: T) -> Data? {
        var encodedData: Data?
        encodeData(product: product) { result in
            switch result {
            case .success(let model):
                encodedData = model
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        return encodedData
    }
}

