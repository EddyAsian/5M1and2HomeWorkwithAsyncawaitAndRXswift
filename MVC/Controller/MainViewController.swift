//
//  MainViewController.swift
//  homework4.4
//
//  Created by Eldar on 1/1/23.
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

class MainViewController: UIViewController {
    
    @IBOutlet private weak var orderMethodCollectionView: UICollectionView!
    @IBOutlet private weak var orderTypeCollectionView: UICollectionView!
    @IBOutlet private weak var takeawaysTableview: UITableView!
    
    private var orderMethodArray = [
        OrderMethodModel(name: "Delivery", img: UIImage(systemName: "car")!, isSelected: false),
        OrderMethodModel(name: "Pickup", img: UIImage(systemName: "shippingbox")!, isSelected: false),
        OrderMethodModel(name: "Catering", img: UIImage(systemName: "fork.knife")!, isSelected: false),
        OrderMethodModel(name: "Curbside", img: UIImage(systemName: "rectangle.roundedtop")!, isSelected: false)
    ]
    
    private var orderTypeArray = [OrderTypeModel]()
    private var takeAways = [ProductModel]() {
        didSet {
            filteredTakeAways = takeAways
            takeawaysTableview.reloadData()
        }
    }
    
    private var filteredTakeAways = [ProductModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        Task {
            do {
                try await configureTakeawaysDataArray()
            } catch {
                print("Error")
            }
        }
        orderTypeArray = NetworkLayer.shared.decodeOrderTypeData(json)
    }
}

extension MainViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if collectionView == orderMethodCollectionView {
            return orderMethodArray.count
        } else {
            return orderTypeArray.count
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if collectionView == orderMethodCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderMethodCollectionViewCell.reuseID,
                for: indexPath) as? OrderMethodCollectionViewCell else { fatalError() }
            
            let orderingMethod = orderMethodArray[indexPath.row]
            cell.displayOrderMethod(orderingMethod)
            if !orderMethodArray[indexPath.row].isSelected {
                cell.backgroundColor = .white
            } else {
                cell.backgroundColor = .yellow
            }
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderTypeCollectionViewCell.reuseID,
                for: indexPath) as? OrderTypeCollectionViewCell else { fatalError() }
            
            let orderType = orderTypeArray[indexPath.row]
            cell.displayOrderType(orderType)
            return cell
        }
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView (
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == orderMethodCollectionView {
            return CGSize(width: 105, height: 40)
        } else {
            return CGSize(width: 100, height: 115)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == orderMethodCollectionView {
            if !orderMethodArray[indexPath.row].isSelected {
                for item in 0..<orderMethodArray.count {
                    orderMethodArray[item].isSelected = false
                }
                orderMethodArray[indexPath.row].isSelected = true
                orderMethodCollectionView.reloadData()
            } else {
                orderMethodArray[indexPath.row].isSelected = false
                orderMethodCollectionView.reloadData()
            }
        } else {
            configureCategoryArrays(indexPath: indexPath)
            takeawaysTableview.reloadData()
        }
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTakeAways.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TakeawaysTableViewCell.tableViewCellReuseID,
            for: indexPath
        ) as? TakeawaysTableViewCell else { fatalError() }
        
        let product = filteredTakeAways[indexPath.row]
        cell.displayInfo(product)
        cell.imageTapped = { productTitle in
            print("Our product is: \(productTitle)")
        }
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 380
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            handleDeleteTakeaways(indexPath: indexPath)
        }
    }
}

extension MainViewController {
    private func configureTakeawaysDataArray() async throws {
        self.takeAways = try await NetworkLayer.shared.fetchProductsData().products
        DispatchQueue.main.async {
            self.takeawaysTableview.reloadData()
        }
    }
    
    private func configureData() {
        orderMethodCollectionView.dataSource = self
        orderMethodCollectionView.delegate = self
        orderMethodCollectionView.register(
            UINib(nibName: String(describing: OrderMethodCollectionViewCell.self), bundle: nil),
            forCellWithReuseIdentifier: OrderMethodCollectionViewCell.reuseID)
        
        orderTypeCollectionView.dataSource = self
        orderTypeCollectionView.delegate = self
        orderTypeCollectionView.register(
            UINib(nibName: String(describing: OrderTypeCollectionViewCell.self), bundle: nil),
            forCellWithReuseIdentifier: OrderTypeCollectionViewCell.reuseID)
        
        takeawaysTableview.dataSource = self
        takeawaysTableview.delegate = self
        takeawaysTableview.register(
            UINib(nibName: String(describing: TakeawaysTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: TakeawaysTableViewCell.tableViewCellReuseID)
    }
    
    private func handleDeleteTakeaways(indexPath:IndexPath) {
        let id = takeAways[indexPath.row].id
        deleteTakeaways(by: id)
        takeAways.remove(at: indexPath.row)
        takeawaysTableview.deleteRows(at: [indexPath], with: .automatic)
    }
    
    private func deleteTakeaways(by id: Int) {
        NetworkLayer.shared.deleteProductsData(id: id) { result in
            if case .failure(let error) = result {
                print(error.localizedDescription)
            }
        }
    }
    
    private func configureCategoryArrays(indexPath: IndexPath) {
        let category = orderTypeArray[indexPath.row].orderLabel.lowercased()
        filteredTakeAways = takeAways.filter { $0.category == category }
    }
}
