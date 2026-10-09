package checkers

import "fmt"

func (g *Game) noProgressLimit() int {
	switch g.Mode {
	case ModeEnglish:
		return EnglishNoProgressPlies
	case ModeCorners:
		return CornersNoProgressPlies
	default:
		return RussianNoProgressPlies
	}
}

func (g *Game) cornersTargetCount(seat int) int {
	tr0, tc0 := 5, 5
	if seat == 1 {
		tr0, tc0 = 0, 0
	}
	n := 0
	for r := tr0; r < tr0+3; r++ {
		for c := tc0; c < tc0+3; c++ {
			if owner(g.at(r, c)) == seat {
				n++
			}
		}
	}
	return n
}

func (g *Game) loneKings() bool {
	var men, kings [2]int
	for _, p := range g.Board {
		switch p {
		case WhiteMan:
			men[0]++
		case BlackMan:
			men[1]++
		case WhiteKing:
			kings[0]++
		case BlackKing:
			kings[1]++
		}
	}
	return men[0] == 0 && men[1] == 0 && kings[0] == 1 && kings[1] == 1
}

func (g *Game) positionKey() string {
	buf := make([]byte, 0, Size*Size+16)
	for _, p := range g.Board {
		buf = append(buf, byte('0'+p))
	}
	cont := 0
	if g.MustContinue {
		cont = 1
	}
	return fmt.Sprintf("%s|%d|%d|%d|%d", buf, g.Turn, cont, g.ContR, g.ContC)
}

func (g *Game) noteProgress(didProgress, cornersProgress bool) {
	if g == nil || g.IsOver() {
		return
	}
	if didProgress || cornersProgress {
		g.NoProgress = 0
	} else {
		g.NoProgress++
	}
	g.checkAutomaticDraw()
}

func (g *Game) checkAutomaticDraw() {
	if g == nil || g.IsOver() {
		return
	}
	if g.isEnglish() && g.loneKings() {
		g.Winner = WinnerDraw
		g.DrawReason = DrawReasonInsufficient
		return
	}
	if g.NoProgress >= g.noProgressLimit() {
		g.Winner = WinnerDraw
		g.DrawReason = DrawReasonNoProgress
		return
	}
	if g.PosCounts == nil {
		g.PosCounts = make(map[string]int)
	}
	key := g.positionKey()
	g.PosCounts[key]++
	if g.PosCounts[key] >= 3 {
		g.Winner = WinnerDraw
		g.DrawReason = DrawReasonRepetition
	}
}
