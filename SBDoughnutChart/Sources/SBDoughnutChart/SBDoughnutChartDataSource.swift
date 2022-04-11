//
//  SBDoughnutChartDataSource.swift
//  SongNodeDemo
//
//  Created by Shubham Bairagi on 04/02/22.
//  Copyright © 2022 Shubham Bairagi. All rights reserved.
//

import UIKit

public protocol SBDoughnutChartDataSource: class {
    
    func numberOfLayers(in pieChart: SBDoughnutChart) -> Int
    
    func pieChart(_ pieChart: SBDoughnutChart, numberOfSliceInLayer layerIndex: Int) -> Int
    
    func pieChart(_ pieChart: SBDoughnutChart, itemForSliceAt slicePath: SlicePath) -> SBDoughnutChartItem
    
    func pieChart(_ pieChart: SBDoughnutChart, innerRadiusInLayer layerIndex: Int) -> CGFloat
    
    func pieChart(_ pieChart: SBDoughnutChart, titleFontAtLayer layerIndex: Int) -> UIFont
    
    func pieChart(_ pieChart: SBDoughnutChart, outerRadiusInLayer layerIndex: Int) -> CGFloat
}

/**
 *  MARK: SBDoughnutChart delegate
 */
public protocol SBDoughnutChartDelegate: class {
    func pieChart(_ pieChart: SBDoughnutChart, didSelectSliceAt slicePath: SlicePath)
}
