//
//  TakeawaysTableViewCell.swift
//  homework4.4
//
//  Created by Eldar on 2/1/23.
//

import UIKit

class TakeawaysTableViewCell: UITableViewCell {
    
    static var tableViewCellReuseID = String(describing: TakeawaysTableViewCell.self)
    
    @IBOutlet private weak var productImage: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var starImage: UIImageView!
    @IBOutlet private weak var ratingLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var brandLabel: UILabel!
    @IBOutlet private weak var discountLabel: UILabel!
    
    private var product: ProductModel?
    public var imageTapped: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTap))
        productImage.isUserInteractionEnabled = true
        productImage.addGestureRecognizer(tap)
    }
    
    func displayInfo(_ item: ProductModel) {
        product = item
        titleLabel.text! = item.title
        descriptionLabel.text = item.description
        ratingLabel.text = "\(item.rating)"
        priceLabel.text = "\(item.price) $"
        discountLabel.text = "\(item.discountPercentage)"
        brandLabel.text = item.brand
        categoryLabel.text = item.category
        loadImgURL(url: item.images.first!)
    }
    
    @objc private func imageTap() {
        guard let product = product else { return }
        imageTapped?(product.title)
    }
    
    private func loadImgURL(url: String) {
        guard let url = URL(string: url) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                self.productImage.image = UIImage(data: data)!
            }
        }
        task.resume()
    }
}
