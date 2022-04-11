//
//  SBDoughnutChart.swift
//  SongNodeDemo
//
//  Created by Shubham Bairagi on 04/02/22.
//  Copyright © 2022 Shubham Bairagi. All rights reserved.
//

import UIKit
import QuartzCore

public struct SlicePath {
    let index: Int
    let layerIndex: Int
}

public class SBDoughnutChart: UIView {
    
    /// Delegate
    public weak var delegate: SBDoughnutChartDelegate?
    
    /// DataSource
    public weak var dataSource: SBDoughnutChartDataSource?
    
    /// Pie chart start angle, should be in [-PI, PI)
    public var startAngle: CGFloat = CGFloat(-(Double.pi / 2)) {
        didSet {
            while startAngle >= CGFloat(Double.pi) {
                startAngle -= CGFloat(Double.pi * 2)
            }
            while startAngle < CGFloat(-Double.pi) {
                startAngle += CGFloat(Double.pi * 2)
            }
        }
    }
    
    /// Offset of selected pie layer
    public var selectedPieOffset: CGFloat = 0.0
    
    /// Font of layer's description text
    public var labelFont: UIFont = UIFont.boldSystemFont(ofSize: 14)
    
    public var showDescriptionText: Bool = false
    
    public var animationDuration: Double = 0
    
    var contentView: UIView!
    
    var pieCenter: CGPoint {
        return CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
    }
    
    var endAngle: CGFloat {
        return CGFloat(Double.pi * 2) + startAngle
    }
    
    var selectedLayerIndex: Int = -1
    
    var total: CGFloat = 0.0
    
    var refresh: Bool = true
    
    func setDefaultValues() {
        contentView = UIView(frame: self.bounds)
        addSubview(contentView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
    }
        
    func drawLayer(Atlayer layerIndex: Int) {
        let parentLayer = contentView.layer
        
        /// Mutable copy of current pie layers on display
        let currentLayers: NSMutableArray = NSMutableArray()
        
        var itemCount: Int = dataSource?.pieChart(self, numberOfSliceInLayer: layerIndex) ?? 0
        
        total = 0
        for index in 0 ..< itemCount {
            let path = SlicePath(index: index, layerIndex: layerIndex)
            let item = dataSource?.pieChart(self, itemForSliceAt: path)
            let value = item?.value ?? 0
            total += value
        }
        
        var diff = itemCount - currentLayers.count
        
        let layersToRemove: NSMutableArray = NSMutableArray()
        
        /**
         *  Begin CATransaction, disable user interaction
         */
        contentView.isUserInteractionEnabled = false
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setCompletionBlock { () -> Void in
            /**
             *  Remove unnecessary layers
             */
            for obj in layersToRemove {
                let layerToRemove: CAShapeLayer = obj as! CAShapeLayer
                layerToRemove.removeFromSuperlayer()
            }
            layersToRemove.removeAllObjects()
            
            /**
             *  Re-enable user interaction
             */
            self.contentView.isUserInteractionEnabled = true
        }
        
        if itemCount == 0 || total <= 0 {
            itemCount = 0
            diff = -currentLayers.count
        }
        
        /**
         *  If there are more new items, add new layers correpsondingly in the beginning, otherwise, remove extra layers from the end
         */
        if diff > 0 {
            while diff != 0 {
                let newLayer = createPieLayer()
                parentLayer.insertSublayer(newLayer, at: 0)
                currentLayers.insert(newLayer, at: 0)
                diff -= 1
            }
        } else if diff < 0 {
            while diff != 0 {
                let layerToRemove = currentLayers.lastObject as! CAShapeLayer
                currentLayers.removeLastObject()
                layersToRemove.add(layerToRemove)
                updateLayer(layer: layerToRemove, atIndex: -1, strokeStart: 1, strokeEnd: 1, slicePath: SlicePath(index: 0, layerIndex: layerIndex))
                diff += 1
            }
        }
        
        var toStrokeStart: CGFloat = 0.0
        var toStrokeEnd: CGFloat = 0.0
        var currentTotal: CGFloat = 0.0
        
        /// Update current layers with corresponding item
        for index: Int in 0 ..< itemCount {
            
            let path = SlicePath(index: index, layerIndex: layerIndex)
            let item = dataSource?.pieChart(self, itemForSliceAt: path)
            
            let currentValue: CGFloat = item?.value ?? 0
            
            let layer = currentLayers[index] as! CAShapeLayer
            
            toStrokeStart = currentTotal / total
            toStrokeEnd = (currentTotal + abs(currentValue)) / total
            updateLayer(layer: layer, atIndex: index, strokeStart: toStrokeStart, strokeEnd: toStrokeEnd, slicePath: path)
            
            currentTotal += currentValue
        }
        CATransaction.commit()
        
    }
    
    public func reloadData() {
        if let layers = dataSource?.numberOfLayers(in: self) {
            
            for i in 0..<layers {
                self.drawLayer(Atlayer: i)
            }
        }
    }
    
    func createPieLayer() -> CAShapeLayer {
        let pieLayer = CAShapeLayer()
        
        pieLayer.fillColor = UIColor.clear.cgColor
        pieLayer.borderColor = UIColor.clear.cgColor
        pieLayer.strokeStart = 0
        pieLayer.strokeEnd = 0
        
        return pieLayer
    }
    
    func createArcAnimationForLayer(layer: CAShapeLayer, key: String, toValue: Any!) {
        
        let arcAnimation: CABasicAnimation = CABasicAnimation(keyPath: key);
        
        var fromValue: Any!
        if key == "strokeStart" || key == "strokeEnd" {
            fromValue = 0
        }
        
        if layer.presentation() != nil {
            fromValue = layer.presentation()!.value(forKey: key)
        }
        
        arcAnimation.fromValue = fromValue
        arcAnimation.toValue = toValue
        layer.add(arcAnimation, forKey: key)
        layer.setValue(toValue, forKey: key)
        
    }
    
    func updateLayer(layer: CAShapeLayer, atIndex index: Int, strokeStart: CGFloat, strokeEnd: CGFloat, slicePath: SlicePath) {
        
        guard let item = dataSource?.pieChart(self, itemForSliceAt: slicePath),
              let outerRadius = dataSource?.pieChart(self, outerRadiusInLayer: slicePath.layerIndex),
              let innerRadius = dataSource?.pieChart(self, innerRadiusInLayer: slicePath.layerIndex) else {
            return
        }
        
        let strokeWidth: CGFloat = outerRadius - innerRadius
        let strokeRadius: CGFloat = (outerRadius + innerRadius) / 2
        
        /// Add animation to stroke path (in case radius changes)
        let path = UIBezierPath(arcCenter: pieCenter, radius: strokeRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        createArcAnimationForLayer(layer: layer, key: "path", toValue: path.cgPath)
        
        layer.lineWidth = strokeWidth
        
        /**
         *  Assign stroke color by data source
         */
        if index >= 0 {
            
            layer.strokeColor = item.color.cgColor
        }
        
        createArcAnimationForLayer(layer: layer, key: "strokeStart", toValue: strokeStart)
        createArcAnimationForLayer(layer: layer, key: "strokeEnd", toValue: strokeEnd)
        
        /// Custom text layer for description
        var textLayer: CATextLayer!
        
        if layer.sublayers != nil {
            textLayer = layer.sublayers!.first as? CATextLayer
        } else {
            textLayer = CATextLayer()
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.isWrapped = true
            layer.addSublayer(textLayer)
        }
        let font = dataSource?.pieChart(self, titleFontAtLayer: slicePath.layerIndex) ?? labelFont
        textLayer.font = CGFont(font.fontName as CFString)
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.fontSize = font.pointSize
        textLayer.string = ""
        
        if showDescriptionText && index >= 0 {
            textLayer.string = item.description
        }
        
        let size: CGSize = (textLayer.string! as AnyObject).size(withAttributes: [NSAttributedString.Key.font: labelFont])
        textLayer.frame = CGRect(origin: .zero, size: size)
        
        if (strokeEnd - strokeStart) * CGFloat(Double.pi) * 2 * strokeRadius < max(size.width, size.height) {
            textLayer.string = ""
        }
        
        let midAngle: CGFloat = (strokeStart + strokeEnd) * CGFloat(Double.pi) + startAngle
        textLayer.position = CGPoint(x: pieCenter.x + strokeRadius * cos(midAngle), y: pieCenter.y + strokeRadius * sin(midAngle))
    }

    func getSelectedLayerIndexOnTouch(touch: UITouch) -> SlicePath? {
        
        let currentPieLayers = contentView.layer.sublayers
        
        if currentPieLayers != nil {
            
            let point = touch.location(in: contentView)

            let layers = dataSource?.numberOfLayers(in: self) ?? 0
            
            var sliceStarter = 0
            var sliceCounter = 0
            
            for layerIndex in 0..<layers {
                let slices = dataSource?.pieChart(self, numberOfSliceInLayer: layerIndex) ?? 0
                let outerRadius = dataSource?.pieChart(self, outerRadiusInLayer: layerIndex) ?? 0
                let innerRadius = dataSource?.pieChart(self, innerRadiusInLayer: layerIndex) ?? 0
                
                sliceCounter = sliceCounter + slices
                
                sliceStarter = sliceCounter - slices
                
                var innerSliceNumber = 0
                
                for i in sliceStarter..<sliceCounter {
                    let pieLayer = currentPieLayers![i] as! CAShapeLayer
                    
                    let pieStartAngle = pieLayer.strokeStart * CGFloat(Double.pi * 2)
                    let pieEndAngle = pieLayer.strokeEnd * CGFloat(Double.pi * 2)
                    
                    var angle = atan2(point.y - pieCenter.y, point.x - pieCenter.x) - startAngle
                    if angle < 0 {
                        angle += CGFloat(Double.pi * 2)
                    }
                    let distance = sqrt(pow(point.x - pieCenter.x, 2) + pow(point.y - pieCenter.y, 2))
                    
                    if angle > pieStartAngle && angle < pieEndAngle && distance < outerRadius && distance > innerRadius {
                        return SlicePath(index: innerSliceNumber, layerIndex: layerIndex)
                    }
                    innerSliceNumber = innerSliceNumber + 1
                }
            }
        }
        return nil
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let anyTouch = touches.first,
           let selectedSlicePath = getSelectedLayerIndexOnTouch(touch: anyTouch) {
            self.delegate?.pieChart(self, didSelectSliceAt: selectedSlicePath)
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame:frame)
        setDefaultValues()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setDefaultValues()
    }
}
