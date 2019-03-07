//
//  ViewController.swift
//  ChartsTest
//
//  Created by Joshua May on 5/3/19.
//  Copyright © 2019 Joshua May. All rights reserved.
//

import UIKit

import Charts

// todo:
// - draw gradient ✅
// - draw ref range (high/low x-axis) ✅
// - draw gradient relative to ref range ✅
// - max 4 values on screen
// - scroll left to reveal extra
// - snap to show 4 on screen, perfectly
// - when < 4 values, centre them
// - line colour to match reference zone ✅

class ViewController: UIViewController {

    @IBOutlet private var container: UIView!

    @IBOutlet private var referenceRangeLowerSlider: UISlider!
    @IBOutlet private var referenceRangeUpperSlider: UISlider!
    @IBOutlet private var referenceRangeLowerLabel: UILabel!
    @IBOutlet private var referenceRangeUpperLabel: UILabel!

    private var chartView: LineChartView!
    private var renderer: XyzLineChartRenderer!

    let grapefruit = UIColor(red: 255/255, green: 94/255, blue: 91/255, alpha: 1)
    let greenblue = UIColor(red: 27/255, green: 188/255, blue: 155/255, alpha: 1)
    let purplish = UIColor(red: 167/255, green: 131/255, blue: 173/255, alpha: 1)
    let darkindigo = UIColor(red: 10/255, green: 34/255, blue: 57/255, alpha: 1)

    private var rrrreferenceRange: ClosedRange<Double> {
        let lower = Double(referenceRangeLowerSlider.value)
        let upper = Double(referenceRangeUpperSlider.value)

        let n = Double(2)
        let v = pow(Double(10), n)
        let lowerRounded = (lower * v).rounded() / v
        let upperRounded = (upper * v).rounded() / v

        if lowerRounded > upperRounded {
            return (upperRounded...lowerRounded)
        }

        return (lowerRounded...upperRounded)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        chartView = LineChartView(frame: container.bounds)

        renderer = XyzLineChartRenderer(dataProvider: chartView, animator: chartView.chartAnimator, viewPortHandler: chartView.viewPortHandler)
        chartView.renderer = renderer

        container.addSubview(chartView)

        chartView.translatesAutoresizingMaskIntoConstraints = false

        container.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[chart]|",
                options: [],
                metrics: nil,
                views: ["chart": chartView]
            )
        )
        container.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[chart]|",
                options: [],
                metrics: nil,
                views: ["chart": chartView]
            )
        )

        sssssetUp()
        rrrrrender()

        sliderValueDidChange(sender: self)
    }

    @IBAction func sliderValueDidChange(sender: Any) {
//        guard let slider = sender as? UISlider else {
//            return
//        }

        referenceRangeLowerLabel.text = String(referenceRangeLowerSlider.value)
        referenceRangeUpperLabel.text = String(referenceRangeUpperSlider.value)

        rrrrrender()

//        if slider == referenceRangeLowerSlider {
//        }
//
//        if slider == referenceRangeUpperSlider {
//            referenceRangeUpperLabel.text = slider.value
//        }
    }

    private func sssssetUp() {
        referenceRangeLowerSlider.value = 0.27
        referenceRangeUpperSlider.value = 2.5

        // config: chart
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.pinchZoomEnabled = false

        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false
        chartView.clipDataToContentEnabled = false
        chartView.chartDescription = nil
        //        chartView.drawBordersEnabled = false
        //        chartView.setExtraOffsets(
        //            left: 20,
        //            top: 20,
        //            right: 20,
        //            bottom: 0
        //        )

        chartView.backgroundColor = darkindigo

        renderer.highLineColor = grapefruit
        renderer.middleLineColor = greenblue
        renderer.lowLineColor = purplish
    }

    private func rrrrrender() {
        let bits: [Double] = [0.56, 0.19, 1.07, 3.16]
        let referenceRange = rrrreferenceRange

        let entries: [ChartDataEntry] = bits
            .enumerated()
            .map { (index, element) in
                return ChartDataEntry(x: Double(index), y: Double(element))
        }

        let line = LineChartDataSet(values: entries, label: "bits")

        line.circleColors = bits.map { bit in
            if bit < referenceRange.lowerBound {
                return purplish
            }

            if bit > referenceRange.upperBound {
                return grapefruit
            }

            return greenblue
        }

        line.axisDependency = .left
        line.mode = .horizontalBezier

        line.fillAlpha = 0.7
        line.drawFilledEnabled = true

        let data = LineChartData(dataSet: line)

        // config: renderer
        renderer.referenceRange = referenceRange

        // config: axes
        let xAxis = chartView.xAxis
        xAxis.granularity = 1
        xAxis.axisMinimum = 0
        xAxis.axisMaximum = Double(bits.count - 1)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = false

        //        let (axisMinimum, axisMaximum) = viewModel.labels.range(for: bins)
        let leftAxis = chartView.leftAxis
        //        leftAxis.setLabelCount(5, force: true)
        leftAxis.granularity = 1
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 5
        leftAxis.drawAxisLineEnabled = true
        leftAxis.gridColor = UIColor.white.withAlphaComponent(0.2)
        leftAxis.gridLineWidth = 2
        leftAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        leftAxis.labelTextColor = .white
        leftAxis.labelPosition = .outsideChart
        leftAxis.centerAxisLabelsEnabled = false
        //        leftAxis.yOffset = -(leftAxis.labelFont.lineHeight * 0.8)

        leftAxis.removeAllLimitLines()

        let llu = ChartLimitLine(limit: referenceRange.upperBound, label: String(referenceRange.upperBound))
        llu.lineColor = greenblue
        llu.lineWidth = 2
        llu.valueTextColor = .white

        let lll = ChartLimitLine(limit: referenceRange.lowerBound, label: String(referenceRange.lowerBound))
        lll.lineColor = greenblue
        lll.lineWidth = 2
        lll.valueTextColor = .white

        leftAxis.addLimitLine(llu)
        leftAxis.addLimitLine(lll)

        // data assignment
        chartView.data = data

        chartView.notifyDataSetChanged()
    }
}
