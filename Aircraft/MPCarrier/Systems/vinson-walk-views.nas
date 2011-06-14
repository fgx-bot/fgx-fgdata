###############################################################################
##
## Walk view configuration for Nimitz or Vinson carrier for FlightGear
##
##  Copyright (C) 2010  Anders Gidenstam  (anders(at)gidenstam.org)
##  Copyright (C) 2010  Vivian Meazza
##  This file is licensed under the GPL license v2 or later.
##
#
################################################################################

# Constraints
var flycoDeck =
    walkview.makeUnionConstraint(

        [walkview.LinePlane.new([ 92.6138, 24.9076, 33.7],
                                [ 92.6138, 23.3755, 33.7], 0.2),
         walkview.LinePlane.new([ 92.6138, 23.3755, 33.7],
                                [ 96.96, 22.45, 33.7], 0.2),
         walkview.LinePlane.new([ 96.96, 22.45, 33.7],
                                [ 99.73, 25.3118, 33.7], 0.2),
         walkview.LinePlane.new([ 99.73, 25.3118, 33.7],
                                [110.1, 25.3118, 33.7], 0.6),
         walkview.LinePlane.new([110.1, 25.3118, 33.7],
                                [117.45, 26.71, 33.7], 0.6),
         walkview.SlopingYAlignedPlane.new([117.45, 26.71, 33.7],
                                           [119.46, 33.21, 33.7]),
         walkview.SlopingYAlignedPlane.new([105.79, 32.23, 33.7],
                                           [117.45, 33.21, 33.7]),
        ]);

var hangarDeck =
    walkview.makeUnionConstraint(
        [
         walkview.SlopingYAlignedPlane.new([7.26949, -11.622, 9.4038],
                                           [188.003, 14.3373, 9.4038]),
        ]);

var priflyDeck =
    walkview.makeUnionConstraint(
        [
        walkview.CircularXYSurface.new([95.2316, 24.969, 33.7], 1.80),
        ]);

var flightDeck =
    walkview.makePolylinePath(
        [
            [-14.7314,   0.0,    21.50],
            [ 13.0324, -28.7233, 21.50],
            [209.362,    0.0,    21.50],
            [  9.72717,  0.0,    21.50],
            [  9.39665, 19.2024, 21.50],
            [ -7.45995, 19.2024, 21.50],
            [-29.6049,   0.0,    21.50],
            [-109.922,   0.0,    21.50],
        ], 20.0);

#var bridgeDeck =
#    walkview.makeUnionConstraint(
#        [
#         walkview.LinePlane.new([94.4187, 23.6247, 31.7419],
#                                [94.4187, 33.8478, 31.7419], 1.75),
#        ]);


# Create the view managers.
var goofer_walker = walkview.Walker.new("Goofers' View", flycoDeck);
var hangar_walker = walkview.Walker.new("Hangar View", hangarDeck);
var prifly_walker = walkview.Walker.new("PriFly View", priflyDeck);
var flghtdeck_walker = walkview.Walker.new("Flightdeck Officer View", flightDeck);
#var bridge_walker = walkview.Walker.new("Bridge View", bridgeDeck);


