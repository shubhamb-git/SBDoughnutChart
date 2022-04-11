//
//  SBDoughnutChartItem.swift
//  SongNodeDemo
//
//  Created by Shubham Bairagi on 04/02/22.
//  Copyright © 2022 Shubham Bairagi. All rights reserved.
//

import UIKit

public class SBDoughnutChartItem {
    
    /// Data value
    public var value: CGFloat = 0.0
    
    /// Color displayed on chart
    public var color: UIColor = UIColor.black
    
    /// Description text
    public var description: String?
    
    public init(value: CGFloat, color: UIColor, description: String?) {
        self.value = value
        self.color = color
        self.description = description
    }
}
