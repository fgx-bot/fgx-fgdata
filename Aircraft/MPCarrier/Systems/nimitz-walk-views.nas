###############################################################################
##
## Walk view configuration for Nimitz or Eisenhower carrier for FlightGear
##
##  Copyright (C) 2010  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

# Constraints
var flycoDeck =
    walkview.makeUnionConstraint(
        [
         walkview.SlopingYAlignedPlane.new([112.3, 26.7, 33.7],
                                           [119.0, 33.5, 33.7]),
         walkview.SlopingYAlignedPlane.new([ 97.1, 32.1, 33.7],
                                           [112.3, 33.5, 33.7]),
         walkview.SlopingYAlignedPlane.new([ 93.7, 29.8, 33.7],
                                           [ 97.1, 36.1, 33.7]),
         walkview.SlopingYAlignedPlane.new([ 93.0, 22.7, 33.7],
                                           [ 93.7, 34.9, 33.7]),
         walkview.SlopingYAlignedPlane.new([ 93.7, 21.9, 33.7],
                                           [ 96.9, 22.7, 33.7]),

         walkview.SlopingYAlignedPlane.new([112.3, 25.5, 33.7],
                                           [113.3, 26.7, 33.7]),
         walkview.SlopingYAlignedPlane.new([ 99.8, 24.9, 33.7],
                                           [112.3, 25.7, 33.7]),

        ]);

# Create the view managers.
var goofer_walker = walkview.Walker.new("Goofers' View", flycoDeck);
