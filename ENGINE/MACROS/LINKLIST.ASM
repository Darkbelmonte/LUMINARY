; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th Augst
; ============================================================================================
; LINKLIST.ASM - A singly linked list
; ============================================================================================

	; Defines a linked list in a memory map or structure (using RS)
LINKED_LIST: macro name
List_\name\_Head	 					rs.l 1
List_\name\_Tail	 					rs.l 1
List_\name\_Size	 					rs.w 1
	endm
	
	; Defines a linked list node in a structure (using RS)
LINKED_LIST_NODE: macro name
List_\name\_Next						rs.l 1
	endm

	; Get number of elements in list
LIST_GET_SIZE: macro name,outreg
	move.w List_\name\_Size,\outreg
	endm
	
	; Appends new link to the end of a list (by list name)
LIST_APPEND: macro name,objaddrreg,tempaddrreg

	; Sanity check - make sure object isn't already in a list
	IFND FINAL

	; Check object's next ptr is null
	cmp.l  #0x0, List_\name\_Next(\objaddrreg)
	beq    @NoNextLink\@
	DBG_RAISE_ERROR "LIST_APPEND_TAIL: Obj already in list"
	@NoNextLink\@:

	; Check object isn't the list head
	move.l List_\name\_Head, \tempaddrreg
	cmp.l  \objaddrreg, \tempaddrreg
	bne    @NotHead\@
	DBG_RAISE_ERROR "LIST_APPEND_TAIL: Obj already in list"
	@NotHead\@:

	; Check object isn't the list tail
	move.l List_\name\_Tail, \tempaddrreg
	cmp.l  \objaddrreg, \tempaddrreg
	bne    @NotTail\@
	DBG_RAISE_ERROR "LIST_APPEND_TAIL: Obj already in list"
	@NotTail\@:

	ENDIF

	; If first in list, set as head and tail
	cmp.l  #0x0, (List_\name\_Head)
	bne    @HasHead\@
	move.l \objaddrreg, List_\name\_Head
	move.l \objaddrreg, List_\name\_Tail
	bra    @End\@
	@HasHead\@:
	
	; else link to current tail, then set as current tail
	move.l (List_\name\_Tail), \tempaddrreg
	move.l \objaddrreg, List_\name\_Next(\tempaddrreg)
	move.l \objaddrreg, List_\name\_Tail
	
	@End\@:
	
	; Increment count
	addq.w #0x1, List_\name\_Size
	
	endm

	; Inserts new link to a list in order
LIST_INSERT_ORDERED: macro name,objaddrreg,tempaddrreg1,tempaddrreg2,orderoffset,order

	; Sanity check - make sure object isn't already in a list
	IFND FINAL

	; Check object's next ptr is null
	cmp.l  #0x0, List_\name\_Next(\objaddrreg)
	beq    @NoNextLink\@
	DBG_RAISE_ERROR "LIST_INSERT_O: Obj already in list"
	@NoNextLink\@:

	; Check object isn't the list head
	move.l List_\name\_Head, \tempaddrreg1
	cmp.l  \objaddrreg, \tempaddrreg1
	bne    @NotHead\@
	DBG_RAISE_ERROR "LIST_INSERT_O: Obj already in list"
	@NotHead\@:

	; Check object isn't the list tail
	move.l List_\name\_Tail, \tempaddrreg1
	cmp.l  \objaddrreg, \tempaddrreg1
	bne    @NotTail\@
	DBG_RAISE_ERROR "LIST_INSERT_O: Obj already in list"
	@NotTail\@:

	ENDIF

	; If first in list, set as head and tail
	cmp.l  #0x0, (List_\name\_Head)
	bne    @HasHead\@
	move.l \objaddrreg, List_\name\_Head
	move.l \objaddrreg, List_\name\_Tail
	bra    @End\@
	@HasHead\@:

	; else search for node < order
	move.l #0x0, \tempaddrreg1								; Clear search result
	move.l (List_\name\_Head), \tempaddrreg2	 			; Get list head
	@EntityLp\@:							 				; For all entities in list
	cmp.l  #0x0, \tempaddrreg2								; If NULL, done
	beq    @Found\@
	cmp.b  \orderoffset(\tempaddrreg2), \order				; If < order
	ble    @Found\@											; Done
	move.l \tempaddrreg2, \tempaddrreg1						; Backup prev link
	move.l List_\name\_Next(\tempaddrreg2), \tempaddrreg2	; Get next ptr
	bra    @EntityLp\@

	@Found\@:

	; If taking head
	cmp.l  #0x0, \tempaddrreg1
	beq    @InsertHead\@
	
	; If taking tail
	cmp.l  #0x0, \tempaddrreg2
	beq    @InsertTail\@
	
	; Set prev obj's next as new obj's next
	move.l List_\name\_Next(\tempaddrreg1), List_\name\_Next(\objaddrreg)

	; Set new item as prev obj's next
	move.l \objaddrreg, List_\name\_Next(\tempaddrreg1)

	bra    @End\@

	@InsertHead\@:

	; Set current head as new obj's next
	move.l List_\name\_Head, List_\name\_Next(\objaddrreg)

	; Set new obj as head
	move.l \objaddrreg, List_\name\_Head
	
	bra    @End\@
	
	@InsertTail\@:
	
	; Set new item as prev obj's next
	move.l \objaddrreg, List_\name\_Next(\tempaddrreg1)
	
	; Set new obj as tail
	move.l \objaddrreg, List_\name\_Tail
	
	@End\@:
	
	; Increment count
	addq.w #0x1, List_\name\_Size

	; Set order
	move.b \order, \orderoffset(\objaddrreg)

	endm
	
	; Removes link from list
LIST_REMOVE: macro name,objaddrreg,tempaddrreg1,tempaddrreg2

	move.l  #0x0, \tempaddrreg1
	
	move.l (List_\name\_Head), \tempaddrreg2	 			; Get list head
	@EntityLp\@:							 				; For all entities in list
	cmp.l  \objaddrreg, \tempaddrreg2						; Check if entity to remove
	beq    @Found\@
	move.l \tempaddrreg2, \tempaddrreg1						; Backup prev
	move.l List_\name\_Next(\tempaddrreg2), \tempaddrreg2	; Get next ptr
	bra    @EntityLp\@

	; Error, object wasn't in this list
	IFND FINAL
	DBG_RAISE_ERROR "LIST_REMOVE: Obj not in list"
	ENDIF
	
	@Found\@:
	
	; Check if new head
	cmp.l  #0x0, \tempaddrreg1
	beq    @NewHead\@
	
	; Link next with prev
	move.l List_\name\_Next(\objaddrreg), List_\name\_Next(\tempaddrreg1)
	bra    @EndLink\@
	
	@NewHead\@:
	
	; Removed entity was head, set new head
	move.l List_\name\_Next(\objaddrreg), List_\name\_Head
	
	@EndLink\@:
	
	; Check if new tail
	cmp.l   #0x0, List_\name\_Next(\objaddrreg)
	bne     @NotTail\@
	
	; Removed entity was tail, set new tail
	move.l  \tempaddrreg1, List_\name\_Tail
	
	@NotTail\@:
	
	; Clear removed object's next link
	move.l #0x0, List_\name\_Next(\objaddrreg)

	; Decrement count
	subq.w #0x1, List_\name\_Size
	
	endm
	
	; Clears list
LIST_CLEAR: macro name,tempaddrreg,tempaddrreg2

	; Clear all links
	move.l (List_\name\_Head), \tempaddrreg
	@EntityLp\@:
	cmp.l  #0x0, \tempaddrreg
	beq    @End\@
	move.l List_\name\_Next(\tempaddrreg), \tempaddrreg2
	move.l #0x0, List_\name\_Next(\tempaddrreg)
	move.l \tempaddrreg2, \tempaddrreg
	bra    @EntityLp\@
	@End\@:

	move.l #0x0, List_\name\_Head
    move.l #0x0, List_\name\_Tail
    move.w #0x0, List_\name\_Size
	endm
	
	; Get the head of a list
LIST_GET_HEAD: macro name,addrreg
	move.l (List_\name\_Head), \addrreg
	endm
	
	; Get next in list
LIST_GET_NEXT: macro name,objaddrreg,outreg
	move.l List_\name\_Next(\objaddrreg), \outreg
	endm
