//
//  XyzLineChartRenderer.swift
//  ChartsTest
//
//  Created by Joshua May on 7/3/19.
//  Copyright © 2019 Joshua May. All rights reserved.
//

import UIKit
import Charts

class XyzLineChartRenderer: LineChartRenderer {
    open var referenceRange: ClosedRange<Double>?

    open var highLineColor: UIColor!
    open var middleLineColor: UIColor!
    open var lowLineColor: UIColor!

    internal var __xBounds = XBounds()

    @objc open override func drawHorizontalBezier(context: CGContext, dataSet: ILineChartDataSet)
    {
        guard let dataProvider = dataProvider else { return }

        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)

        let phaseY = animator.phaseY

        __xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)

        // get the color that is specified for this position from the DataSet
//        let drawingColor = dataSet.colors.first!

        // the path for the cubic-spline
        let cubicPath = CGMutablePath()

        let valueToPixelMatrix = trans.valueToPixelMatrix

        if __xBounds.range >= 1
        {
            var prev: ChartDataEntry! = dataSet.entryForIndex(__xBounds.min)
            var cur: ChartDataEntry! = prev

            if cur == nil { return }

            // let the spline start
            cubicPath.move(to: CGPoint(x: CGFloat(cur.x), y: CGFloat(cur.y * phaseY)), transform: valueToPixelMatrix)

            for j in stride(from: (__xBounds.min + 1), through: __xBounds.range + __xBounds.min, by: 1)
            {
                prev = cur
                cur = dataSet.entryForIndex(j)

                let cpx = CGFloat(prev.x + (cur.x - prev.x) / 2.0)

                cubicPath.addCurve(
                    to: CGPoint(
                        x: CGFloat(cur.x),
                        y: CGFloat(cur.y * phaseY)),
                    control1: CGPoint(
                        x: cpx,
                        y: CGFloat(prev.y * phaseY)),
                    control2: CGPoint(
                        x: cpx,
                        y: CGFloat(cur.y * phaseY)),
                    transform: valueToPixelMatrix)
            }
        }

        context.saveGState()

        if dataSet.isDrawFilledEnabled
        {
            // Copy this path because we make changes to it
            let fillPath = cubicPath.mutableCopy()

            drawCubicFill(context: context, dataSet: dataSet, spline: fillPath!, matrix: valueToPixelMatrix, bounds: __xBounds)
        }

        let topPath = cubicPath
        let middlePath = cubicPath
        let bottomPath = cubicPath

        let rangeTop = referenceRange!.upperBound
        let rangeBottom = referenceRange!.lowerBound

        let rangeTopPoint = trans.pixelForValues(x: 0, y: rangeTop)
        let rangeBottomPoint = trans.pixelForValues(x: 0, y: rangeBottom)

        let rrrect = viewPortHandler.contentRect

        let lineWidth = CGFloat(3)

        context.saveGState()
        context.clip(to: CGRect(x: rrrect.minX, y: rrrect.minY, width: rrrect.width, height: rangeTopPoint.y))
        context.beginPath()
        context.addPath(topPath)
        context.setStrokeColor(highLineColor.cgColor)
        context.setLineWidth(lineWidth)
        context.strokePath()
        context.restoreGState()

        context.saveGState()
        context.clip(to: CGRect(x: rrrect.minX, y: rangeTopPoint.y, width: rrrect.width, height: rangeBottomPoint.y - rangeTopPoint.y))
        context.beginPath()
        context.addPath(middlePath)
        context.setStrokeColor(middleLineColor.cgColor)
        context.setLineWidth(lineWidth)
        context.strokePath()
        context.restoreGState()

        context.saveGState()
        context.clip(to: CGRect(x: rrrect.minX, y: rangeBottomPoint.y, width: rrrect.width, height: rrrect.height - rangeBottomPoint.y))
        context.beginPath()
        context.addPath(bottomPath)
        context.setStrokeColor(lowLineColor.cgColor)
        context.setLineWidth(lineWidth)
        context.strokePath()
        context.restoreGState()

        context.restoreGState()
    }

    open override func drawCubicFill(
        context: CGContext,
        dataSet: ILineChartDataSet,
        spline: CGMutablePath,
        matrix: CGAffineTransform,
        bounds: XBounds)
    {
        guard
            let dataProvider = dataProvider
            else { return }

        if bounds.range <= 0
        {
            return
        }

        let fillMin = dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0

        var pt1 = CGPoint(x: CGFloat(dataSet.entryForIndex(bounds.min + bounds.range)?.x ?? 0.0), y: fillMin)
        var pt2 = CGPoint(x: CGFloat(dataSet.entryForIndex(bounds.min)?.x ?? 0.0), y: fillMin)
        pt1 = pt1.applying(matrix)
        pt2 = pt2.applying(matrix)

        spline.addLine(to: pt1)
        spline.addLine(to: pt2)
        spline.closeSubpath()

        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)

        drawFill(context: context, path: spline, fillAlpha: dataSet.fillAlpha, trans: trans)

//        if dataSet.fill != nil
//        {
//            drawFilledPath(context: context, path: spline, fill: dataSet.fill!, fillAlpha: dataSet.fillAlpha)
//        }
//        else
//        {
//            drawFilledPath(context: context, path: spline, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
//        }
    }

    func drawFill(context: CGContext, path: CGPath, fillAlpha: CGFloat, trans: Transformer) {
//        guard let dataProvider = dataProvider else { return }
//
//        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)

        context.saveGState()
        context.beginPath()
        context.addPath(path)

        // filled is usually drawn with less alpha
        context.setAlpha(fillAlpha)

        let rangeTop = referenceRange!.upperBound
        let rangeBottom = referenceRange!.lowerBound

        let rangeTopPoint = trans.pixelForValues(x: 0, y: rangeTop)
        let rangeBottomPoint = trans.pixelForValues(x: 0, y: rangeBottom)
        let rangeHeight = rangeTopPoint.y - rangeBottomPoint.y
        let overflowFactor = CGFloat(0.2)

        let colours = [
            lowLineColor.cgColor,
            middleLineColor.cgColor,
            highLineColor.cgColor,
            ] as CFArray
        let gradient = CGGradient(colorsSpace: nil, colors: colours, locations: nil)!

        let rect = viewPortHandler.contentRect

        let radians = CGFloat((360.0 - 90) * .pi / 180)
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let xAngleDelta = cos(radians) * rect.width / 2.0
//        let yAngleDelta = sin(radians) * rect.height / 2.0
        let startPoint = CGPoint(
            x: centerPoint.x - xAngleDelta,
//            y: centerPoint.y - yAngleDelta
            y: rangeBottomPoint.y - (rangeHeight * overflowFactor)
        )
        let endPoint = CGPoint(
            x: centerPoint.x + xAngleDelta,
//            y: centerPoint.y + yAngleDelta
            y: rangeTopPoint.y + (rangeHeight * overflowFactor)
        )

        context.clip()
        context.drawLinearGradient(gradient,
                                   start: startPoint,
                                   end: endPoint,
                                   options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )

        context.restoreGState()
    }
}
