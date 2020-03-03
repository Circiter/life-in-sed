#!/bin/sed -Enf

# (c) Circiter (mailto:xcirciter@gmail.com).
# Official source: github.com/Circiter/life-in-sed
# License: MIT.

# Bug: too slow.

# Conway's Game of Life in sed.

# Example usage: cat glider.seed | ./life.sed

:load $!{N; bload}; G

:generation
    s/^x/X/; s/^y/Y/ # Initial position of the scanning window.

    h
    # Insert "a water-mark" to the hold space to
    # differenciate it from the pattern space in the future.
    x; s/$/h/; x

    # Insert stop-markers, @, before and after the matrix;
    # then duplicate the last line.
    s/^(.*)(\n[^\n]*)\n$/@\1\2@\2/

    # Slide the window across the matrix and count a live
    # cells in the pointed neighborhood of each matrix entry.
    :scan
        # Initialize a counter in the hold space.
        x; s/^.*$/\n&/; x

        # Insert auxiliary markers.
        s/[XY]/<&>/; s/\n</<\n/; s/>\n/\n>/

        # Shift the aux-markers in two opposite directions,
        # one character at a time.
        :shift
            s/@</@/; s/>@/@/
            s/([^@])</<\1/; s/\n</<\n/ # The first marker moves to the left.
            s/>([^@])/\1>/; s/>\n/\n>/ # The second marker moves to the right.

            s/(\n[^\n]*)[^\n]$/\1/ # Shorten the last duplicated line.
            /[^\n]$/bshift # While the last line is not empty.

        # Now the first aux. marker is located just after the NW
        # corner, if any, of 8-neighborhood of the main X/Y marker. The second
        # marker, correspondingly, is located just before the SE corner, if any.
        /y[XY]/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # W.
        /[XY]y/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # E.
        /y<[^\n]/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # NW.
        /<[\n]*[^\n]y/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # NE.
        /<[\n]*y/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # N.
        /[^\n]>y/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # SE.
        /y[^\n][\n]*>/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # SW.
        /y[\n]*>/{x; s/^(x*)\n(.*)$/\1x\n\2/; x} # S.

        s/[<>]//g; # Remove the auxiliary markers.

        # Edit the hold space (the next generation).
        x

        # Under population: Any live cell with fewer than two live neighbors dies.
        # Over population: Any live cell with more than three live neighbors dies.
        # Reproduction: Any dead cell with exactly three live neighbors becomes a live cell.
        # Sustainability: Any live cell with two or three live neighbors lives on to the next generation.
        /^xxx\n/{s/X/Y/; bsurvive} # Born.
        /^xx\n/bsurvive
        s/Y/X/ # Die
        :survive

        s/^x*\n// # Remove the counter.

        # Move the marker synchronously in both buffers.
        :again
            s/[XY][xy]/&c/
            s/[XY]\n[xy]/&c/
            s/([XY])@/\1#/ # Insert a termination flag.
            y/XY/xy/
            s/xc/X/g; s/yc/Y/g
            /h$/{x; bagain} # If we are in the hold space.

        # Duplicate the last line.
        s/^(.*)(\n[^\n]*)@.*$/\1\2@\2/
        /#/!bscan

    # Check for stabilization.
    s/@//; G; s/h//
    # Pattern space: old_generation#new_generation
    # Compare both generations.
    :compare s/^(.)(.*#\n\n)\1/\2/; tcompare
    /^#\n/{x; s/$/\nstabilized/; x}

    g # Copy the newly created generation to the pattern space.
    y/XY/xy/; s/h// # Prepare for further processing.

    y/xy/ #/
    s/^/\x1b\[\?25l\x1b\[H/; p; s/\x1b\[\?25l\x1b\[H// # Display.
    y/ #/xy/

    # "Follow me"-mode.
    s/^/\n/;
    # Scroll horizontally.
    /y..\n/ {s/\n[xy]/\n/g; s/^\n//; s/\n/x\n/g;}
    s/^\n//;
    # Scroll vertically.
    /\nx*yx*\n[xy]*\n[xy]*$/ {s/^[xy]*\n//; s/([xy]*\n)$/\1\1/}

    /stabilized$/!bgeneration
