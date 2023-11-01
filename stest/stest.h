\newif\ifspace \newif\iffunny \newif\ifexplicit \newif\ifactive
\def\stest#1{%\tracingmacros=2 \tracingonline=1
  \funnyfalse
  \expandafter\s\the#1! \stest}
\def\s{
  \global\explicitfalse
  \global\activefalse
  \futurelet\next\ss}
\def\ss{
  \ifcat\noexpand\next\stoken
    \let\nxt\sx
  \else
    \let\nxt\ns
  \fi
  \nxt}
\def\sx{
  \spacetrue
  \ifx\next\stoken
    \let\nxt\sss
  \else
    \let\nxt=\ssss
  \fi
  \nxt}
\long\def\sss#1 #2\stest{
  \def\next{#1}
  \ifx\next\empty
    \global\explicittrue
  \else
    \testactive#1\s
  \fi}
\long\def\ssss#1#2\stest{
  \funnytrue
  \begingroup
    \escapechar=\if*#1`?\else`*\fi\relax
    \if#1\string#1
      \uccode`#1=`~ % we assume that ~ is an active character
      \uppercase{\ifcat\noexpand#1}\noexpand~
        \global\activetrue
      \else
        \global\explicittrue
      \fi
    \else
      \testactive#1\s
    \fi
  \endgroup}
\long\def\ns#1\stest{
  \spacefalse}
\long\def\testactive#1#2\s{
  \expandafter\tact\string#1\s\tact}
\long\def\tact#1#2\tact{
  \def\next{#2}
  \ifx\next\xs
    \global\activetrue
  \else
    \ifx\next\empty
      \global\activetrue
    \fi
  \fi}
\def\xs{\s}
\def\\{\let\stoken= } \\
\def\report{
  \ifspace\message{SPACE}\fi
  \iffunny\message{FUNNY}\fi
  \ifexplicit\message{EXPLICIT}\fi
  \ifactive\message{ACTIVE}\fi}
