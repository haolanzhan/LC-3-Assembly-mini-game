; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;   Name: Haolan Zhan
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc

	;; Place your code here
	invoke DrawStar, 50, 50 ;; Draw a single star at the location (50,50)
	invoke DrawStar, 168, 20 ;; Draw a single star at the location (168,20)
	invoke DrawStar, 20, 380 ;; Draw a single star at the location (20,380)
	invoke DrawStar, 524, 128 ;; Draw a single star at the location (524,128)
	
	invoke DrawStar, 620, 300 ;; Draw a single star at the location (620,300)
	invoke DrawStar, 345, 125 ;; Draw a single star at the location (345, 125)
	invoke DrawStar, 80, 460 ;; Draw a single star at the location (80, 460)
	invoke DrawStar, 543, 39 ;; Draw a single star at the location (543, 39)
	
	invoke DrawStar, 192, 345 ;; Draw a single star at the location (192, 345)
	invoke DrawStar, 600, 239 ;; Draw a single star at the location (600, 239)
	invoke DrawStar, 100, 100 ;; Draw a single star at the location (100, 100)
	invoke DrawStar, 200, 200 ;; Draw a single star at the location (200, 200)
	
	invoke DrawStar, 300, 300 ;; Draw a single star at the location (300, 300)
	invoke DrawStar, 300, 305 ;; Draw a single star at the location (300, 305)
	invoke DrawStar, 300, 310 ;; Draw a single star at the location (300, 310)
	invoke DrawStar, 300, 315 ;; Draw a single star at the location (300, 315)
	invoke DrawStar, 300, 320 ;; Draw a single star at the location (300, 320)
	invoke DrawStar, 315, 300 ;; Draw a single star at the location (315, 300)
	invoke DrawStar, 315, 305 ;; Draw a single star at the location (315, 305)
	invoke DrawStar, 315, 310 ;; Draw a single star at the location (315, 310)
	invoke DrawStar, 315, 315 ;; Draw a single star at the location (315, 315)
	invoke DrawStar, 315, 320 ;; Draw a single star at the location (315, 320)
	invoke DrawStar, 305, 310 ;; Draw a single star at the location (305, 310)
	invoke DrawStar, 310, 310 ;; Draw a single star at the location (310, 310)


	ret  			; Careful! Don't remove this line
DrawStarField endp



END
