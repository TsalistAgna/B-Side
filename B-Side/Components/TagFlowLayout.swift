//
//  TagFlowLayout.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI

struct TagFlowLayout: Layout {

    var spacing: CGFloat = 6

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {

        let availableWidth =
            proposal.width ?? .infinity

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0

        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0


        for subview in subviews {

            let size =
                subview.sizeThatFits(
                    .unspecified
                )


            // Move to next row
            if currentX > 0 &&
                currentX + size.width > availableWidth {

                currentX = 0

                currentY +=
                    rowHeight + spacing

                rowHeight = 0
            }


            currentX += size.width

            totalWidth = max(
                totalWidth,
                currentX
            )

            currentX += spacing

            rowHeight = max(
                rowHeight,
                size.height
            )
        }


        return CGSize(
            width: min(
                totalWidth,
                availableWidth
            ),
            height:
                currentY + rowHeight
        )
    }


    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {

        var x = bounds.minX
        var y = bounds.minY

        var rowHeight: CGFloat = 0


        for subview in subviews {

            let size =
                subview.sizeThatFits(
                    .unspecified
                )


            if x > bounds.minX &&
                x + size.width > bounds.maxX {

                x = bounds.minX

                y +=
                    rowHeight + spacing

                rowHeight = 0
            }


            subview.place(
                at: CGPoint(
                    x: x,
                    y: y
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: size.width,
                    height: size.height
                )
            )


            x += size.width + spacing

            rowHeight = max(
                rowHeight,
                size.height
            )
        }
    }
}
