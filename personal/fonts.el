(prelude-require-package 'ligature)

(when (window-system)
  (set-frame-font "Monaspace Neon"))

(use-package ligature
  :config
  (let ((ligs
         '(;; == === => =| =>>=>=|=>==>> ==< =/=//=// =~ =:= =!=
           ("=" (rx (+ (or ">" "<" "|" "/" "~" ":" "!" "="))))
           ;; ;; ;;;
           (";" (rx (+ ";")))
           ;; && &&&
           ("&" (rx (+ "&")))
           ;; !! !!! !. !: !!. != !== !~
           ("!" (rx (+ (or "=" "!" "\." ":" "~"))))
           ;; ?? ??? ?:  ?=  ?.
           ("?" (rx (or ":" "=" "\." (+ "?"))))
           ;; %% %%%
           ("%" (rx (+ "%")))
           ;; |> ||> |||> ||||> |] |} || ||| |-> ||-||
           ;; |->>-||-<<-| |- |== ||=||
           ;; |==>>==<<==<=>==//==/=!==:===>
           ("|" (rx (+ (or ">" "<" "|" "/" ":" "!" "}" "\]"
                           "-" "=" ))))
           ;; \\ \\\ \/
           ("\\" (rx (or "/" (+ "\\"))))
           ;; ++ +++ ++++ +>
           ("+" (rx (or ">" (+ "+"))))
           ;; :: ::: :::: :> :< := :// ::=
           (":" (rx (or ">" "<" "=" "//" ":=" (+ ":"))))
           ;; // /// //// /\ /* /> /===:===!=//===>>==>==/
           ("/" (rx (+ (or ">"  "<" "|" "/" "\\" "\*" ":" "!"
                           "="))))
           ;; .. ... .... .= .- .? ..= ..<
           ("\." (rx (or "=" "-" "\?" "\.=" "\.<" (+ "\."))))
           ;; -- --- ---- -~ -> ->> -| -|->-->>->--<<-|
           ("-" (rx (+ (or ">" "<" "|" "~" "-"))))
           ;; *> */ *)  ** *** ****
           ("*" (rx (or ">" "/" ")" (+ "*"))))
           ;; www wwww
           ("w" (rx (+ "w")))
           ;; <> <!-- <|> <: <~ <~> <~~ <+ <* <$ </  <+> <*>
           ;; <$> </> <|  <||  <||| <|||| <- <-| <-<<-|-> <->>
           ;; <<-> <= <=> <<==<<==>=|=>==/==//=!==:=>
           ;; << <<< <<<<
           ("<" (rx (+ (or "\+" "\*" "\$" "<" ">" ":" "~"  "!"
                           "-"  "/" "|" "="))))
           ;; >: >- >>- >--|-> >>-|-> >= >== >>== >=|=:=>>
           ;; >> >>> >>>>
           (">" (rx (+ (or ">" "<" "|" "/" ":" "=" "-"))))
           ;; #: #= #! #( #? #[ #{ #_ #_( ## ### #####
           ("#" (rx (or ":" "=" "!" "(" "\?" "\[" "{" "_(" "_"
                        (+ "#"))))
           ;; ~~ ~~~ ~=  ~-  ~@ ~> ~~>
           ("~" (rx (or ">" "=" "-" "@" "~>" (+ "~")))))))
    (ligature-set-ligatures 'prog-mode ligs)))

;; (let ((alist '((33 . ".\\(?:\\(?:==\\|!!\\)\\|[!=]\\)")
;;                (35 . ".\\(?:###\\|##\\|_(\\|[#(?[_{]\\)")
;;                (36 . ".\\(?:>\\)")
;;                (37 . ".\\(?:\\(?:%%\\)\\|%\\)")
;;                (38 . ".\\(?:\\(?:&&\\)\\|&\\)")
;;                (42 . ".\\(?:\\(?:\\*\\*/\\)\\|\\(?:\\*[*/]\\)\\|[*/>]\\)")
;;                (43 . ".\\(?:\\(?:\\+\\+\\)\\|[+>]\\)")
;;                (45 . ".\\(?:\\(?:-[>-]\\|<<\\|>>\\)\\|[<>}~-]\\)")
;;                ;; (46 . ".\\(?:\\(?:\\.[.<]\\)\\|[.=-]\\)")
;;                (47 . ".\\(?:\\(?:\\*\\*\\|//\\|==\\)\\|[*/=>]\\)")
;;                (48 . ".\\(?:x[a-zA-Z]\\)")
;;                (58 . ".\\(?:::\\|[:=]\\)")
;;                (59 . ".\\(?:;;\\|;\\)")
;;                (60 . ".\\(?:\\(?:!--\\)\\|\\(?:~~\\|->\\|\\$>\\|\\*>\\|\\+>\\|--\\|<[<=-]\\|=[<=>]\\||>\\)\\|[*$+~/<=>|-]\\)")
;;                (61 . ".\\(?:\\(?:/=\\|:=\\|<<\\|=[=>]\\|>>\\)\\|[<=>~]\\)")
;;                (62 . ".\\(?:\\(?:=>\\|>[=>-]\\)\\|[=>-]\\)")
;;                (63 . ".\\(?:\\(\\?\\?\\)\\|[:=?]\\)")
;;                (91 . ".\\(?:]\\)")
;;                (92 . ".\\(?:\\(?:\\\\\\\\\\)\\|\\\\\\)")
;;                (94 . ".\\(?:=\\)")
;;                (119 . ".\\(?:ww\\)")
;;                (123 . ".\\(?:-\\)")
;;                (124 . ".\\(?:\\(?:|[=|]\\)\\|[=>|]\\)")
;;                (126 . ".\\(?:~>\\|~~\\|[>=@~-]\\)")
;;                )
;;              ))
;;  (dolist (char-regexp alist)
;;    (set-char-table-range composition-function-table (car char-regexp)
;;                          `([,(cdr char-regexp) 0 font-shape-gstring]))))
