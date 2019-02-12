################################################################################
#
# Makefile
#
# Makefile to build the custom Raspbian image 
#
################################################################################
#
# Copyright (C) 2018 Darren Young <darren@yhlsecurity.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
################################################################################
#
# TODO/ISSUES:
#
################################################################################


################################################################################
# 
# Various vim modelines to make Makefiles work correctly, notably tabs.
# Yea yea, modelines are evil security things, get over it.
#
# vim: set noexpandtab:
# vim: set syntax=makefile:
#
################################################################################



################################################################################
#
################################################################################

# All-er-(ish) target
all:
	# Guess what this does...
	cp rc.local /etc
