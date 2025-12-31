import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

// D3.js Interactive Tournament Bracket Controller
export default class extends Controller {
  static targets = ["svg", "container", "zoomControls", "championOverlay", "confetti", "loading"]

  static values = {
    data: Object,
    knockoutPath: String,
    quickWinnerPath: String
  }

  // Layout constants - BIGGER for better readability
  static MATCH_WIDTH = 220
  static MATCH_HEIGHT = 90
  static ROUND_GAP = 45
  static VERTICAL_GAP = 25
  static PADDING = 35

  // Mobile breakpoint
  static MOBILE_BREAKPOINT = 768

  // Round configurations
  static ROUNDS = {
    round_of_32: { left: [49, 50, 51, 52, 53, 54, 55, 56], right: [57, 58, 59, 60, 61, 62, 63, 64] },
    round_of_16: { left: [65, 66, 67, 68], right: [69, 70, 71, 72] },
    quarter_final: { left: [73, 74], right: [75, 76] },
    semi_final: { left: [77], right: [78] },
    final: { center: [80] },
    third_place: { center: [79] }
  }

  // Progression map
  static PROGRESSION = {
    65: [49, 50], 66: [51, 52], 67: [53, 54], 68: [55, 56],
    69: [57, 58], 70: [59, 60], 71: [61, 62], 72: [63, 64],
    73: [65, 66], 74: [67, 68], 75: [69, 70], 76: [71, 72],
    77: [73, 74], 78: [75, 76],
    80: [77, 78],
    79: [77, 78]
  }

  connect() {
    this.matchPositions = new Map()
    this.currentZoom = d3.zoomIdentity
    this.isConnected = true
    this.isMobile = window.innerWidth < this.constructor.MOBILE_BREAKPOINT

    this.initializeBracket()
    this.setupZoom()
    this.setupResizeListener()

    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = "none"
    }

    // Check if we should center on next match (after selection on mobile)
    if (this.isMobile && window._nextMatchToCenter) {
      const nextMatch = window._nextMatchToCenter
      window._nextMatchToCenter = null
      setTimeout(() => {
        this.centerOnMatch(nextMatch)
      }, 300)
    }
  }

  disconnect() {
    this.isConnected = false
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  setupResizeListener() {
    let resizeTimeout
    window.addEventListener("resize", () => {
      clearTimeout(resizeTimeout)
      resizeTimeout = setTimeout(() => {
        const wasMobile = this.isMobile
        this.isMobile = window.innerWidth < this.constructor.MOBILE_BREAKPOINT
        if (wasMobile !== this.isMobile) {
          this.initializeBracket()
        }
      }, 250)
    })
  }

  // ==================== INITIALIZATION ====================

  initializeBracket() {
    const data = this.dataValue
    if (!data || !data.matches || data.matches.length === 0) {
      console.warn("No bracket data available")
      return
    }

    this.matches = new Map(data.matches.map(m => [m.matchNumber, m]))
    this.predictions = data.predictions || {}
    this.quickMode = data.quickMode
    this.championId = data.championId

    if (this.isMobile) {
      this.calculateMobileLayout()
    } else {
      this.calculateLayout()
    }

    this.renderBracket()
    this.animateEntrance()

    if (this.championId && this.hasChampionOverlayTarget) {
      this.showChampionCelebration()
    }
  }

  calculateLayout() {
    const MW = this.constructor.MATCH_WIDTH
    const MH = this.constructor.MATCH_HEIGHT
    const RG = this.constructor.ROUND_GAP
    const VG = this.constructor.VERTICAL_GAP
    const PAD = this.constructor.PADDING

    const columns = [0, 1, 2, 3, 4, 5, 6, 7, 8].map(i => PAD + i * (MW + RG))

    const r32Height = 8 * MH + 7 * VG
    this.totalHeight = r32Height + PAD * 2
    this.totalWidth = columns[8] + MW + PAD

    const positionRound = (matchNumbers, column, matchCount, baseMatchCount = 8) => {
      const totalSpace = baseMatchCount * MH + (baseMatchCount - 1) * VG
      const spacing = totalSpace / matchCount
      const startY = PAD + (spacing - MH) / 2

      matchNumbers.forEach((num, idx) => {
        this.matchPositions.set(num, {
          x: columns[column],
          y: startY + idx * spacing,
          width: MW,
          height: MH
        })
      })
    }

    positionRound(this.constructor.ROUNDS.round_of_32.left, 0, 8)
    positionRound(this.constructor.ROUNDS.round_of_16.left, 1, 4)
    positionRound(this.constructor.ROUNDS.quarter_final.left, 2, 2)
    positionRound(this.constructor.ROUNDS.semi_final.left, 3, 1)

    positionRound(this.constructor.ROUNDS.round_of_32.right, 8, 8)
    positionRound(this.constructor.ROUNDS.round_of_16.right, 7, 4)
    positionRound(this.constructor.ROUNDS.quarter_final.right, 6, 2)
    positionRound(this.constructor.ROUNDS.semi_final.right, 5, 1)

    const centerX = columns[4]
    const centerY = this.totalHeight / 2

    this.matchPositions.set(80, {
      x: centerX,
      y: centerY - MH / 2 - 30,
      width: MW,
      height: MH,
      isFinal: true
    })

    this.matchPositions.set(79, {
      x: centerX,
      y: centerY + MH / 2 + 20,
      width: MW,
      height: MH,
      isThirdPlace: true
    })

    this.trophyPosition = {
      x: centerX + MW / 2,
      y: PAD + 20
    }
  }

  calculateMobileLayout() {
    // Mobile: Two-sided vertical bracket like desktop but rotated
    // Left bracket on left, Right bracket on right, Final at bottom center
    // User scrolls horizontally to see both sides

    const MW = 56   // Match width
    const MH = 60   // Match height
    const HG = 20   // Horizontal gap between columns (rounds)
    const VG = 12   // Vertical gap between matches in same round
    const PAD = 15
    const BRACKET_GAP = 60 // Gap between left and right brackets

    // Each bracket side has 4 columns: R32 -> R16 -> QF -> SF
    const bracketWidth = 4 * MW + 3 * HG
    this.totalWidth = bracketWidth * 2 + BRACKET_GAP + PAD * 2

    // Height based on R32 (8 matches)
    const r32Height = 8 * MH + 7 * VG

    // Position helper for vertical column of matches
    const positionColumn = (matchNumbers, column, bracketSide, matchCount, baseMatchCount = 8) => {
      const bracketStartX = bracketSide === 'left'
        ? PAD
        : PAD + bracketWidth + BRACKET_GAP

      // Column position within bracket (0=R32, 1=R16, 2=QF, 3=SF)
      const colX = bracketSide === 'left'
        ? bracketStartX + column * (MW + HG)
        : bracketStartX + (3 - column) * (MW + HG) // Reversed for right side

      const totalSpace = baseMatchCount * MH + (baseMatchCount - 1) * VG
      const spacing = totalSpace / matchCount
      const startY = PAD + 25 + (spacing - MH) / 2 // +25 for labels

      matchNumbers.forEach((num, idx) => {
        this.matchPositions.set(num, {
          x: colX,
          y: startY + idx * spacing,
          width: MW,
          height: MH
        })
      })
    }

    // Left bracket (columns 0-3 from left)
    positionColumn(this.constructor.ROUNDS.round_of_32.left, 0, 'left', 8)
    positionColumn(this.constructor.ROUNDS.round_of_16.left, 1, 'left', 4)
    positionColumn(this.constructor.ROUNDS.quarter_final.left, 2, 'left', 2)
    positionColumn(this.constructor.ROUNDS.semi_final.left, 3, 'left', 1)

    // Right bracket (columns 0-3 from right, mirrored)
    positionColumn(this.constructor.ROUNDS.round_of_32.right, 0, 'right', 8)
    positionColumn(this.constructor.ROUNDS.round_of_16.right, 1, 'right', 4)
    positionColumn(this.constructor.ROUNDS.quarter_final.right, 2, 'right', 2)
    positionColumn(this.constructor.ROUNDS.semi_final.right, 3, 'right', 1)

    // Final and 3rd place at center bottom
    const centerX = this.totalWidth / 2
    const finalY = PAD + 25 + r32Height + 40

    this.matchPositions.set(80, {
      x: centerX - MW * 0.7,
      y: finalY,
      width: MW * 1.4,
      height: MH,
      isFinal: true
    })

    this.matchPositions.set(79, {
      x: centerX - MW / 2,
      y: finalY + MH + 20,
      width: MW,
      height: MH * 0.9,
      isThirdPlace: true
    })

    this.totalHeight = finalY + MH * 2 + 40

    // Round labels
    this.mobileRoundLabels = [
      // Left side labels (top)
      { name: "32e", y: PAD + 12, x: PAD + MW / 2 },
      { name: "16e", y: PAD + 12, x: PAD + MW + HG + MW / 2 },
      { name: "QF", y: PAD + 12, x: PAD + 2 * (MW + HG) + MW / 2 },
      { name: "SF", y: PAD + 12, x: PAD + 3 * (MW + HG) + MW / 2 },
      // Right side labels (top)
      { name: "SF", y: PAD + 12, x: PAD + bracketWidth + BRACKET_GAP + MW / 2 },
      { name: "QF", y: PAD + 12, x: PAD + bracketWidth + BRACKET_GAP + MW + HG + MW / 2 },
      { name: "16e", y: PAD + 12, x: PAD + bracketWidth + BRACKET_GAP + 2 * (MW + HG) + MW / 2 },
      { name: "32e", y: PAD + 12, x: PAD + bracketWidth + BRACKET_GAP + 3 * (MW + HG) + MW / 2 },
      // Center labels
      { name: "🏆 FINALE", y: finalY - 8, x: centerX },
      { name: "3ème", y: finalY + MH + 12, x: centerX },
    ]

    this.trophyPosition = { x: centerX, y: finalY - 30 }
    this.mobileConnectors = true
  }

  // ==================== RENDERING ====================

  renderBracket() {
    const svg = d3.select(this.svgTarget)

    svg.selectAll("*").remove()

    svg
      .attr("viewBox", `0 0 ${this.totalWidth} ${this.totalHeight}`)
      .attr("preserveAspectRatio", "xMidYMid meet")

    // Add gradient definitions
    const defs = svg.append("defs")

    const connectorGradient = defs.append("linearGradient")
      .attr("id", "connectorGradient")
      .attr("gradientUnits", "userSpaceOnUse")
    connectorGradient.append("stop").attr("offset", "0%").attr("stop-color", "rgba(196, 167, 125, 0.3)")
    connectorGradient.append("stop").attr("offset", "100%").attr("stop-color", "rgba(196, 167, 125, 0.5)")

    const finalGradient = defs.append("linearGradient")
      .attr("id", "finalGradient")
      .attr("x1", "0%").attr("y1", "0%").attr("x2", "100%").attr("y2", "100%")
    finalGradient.append("stop").attr("offset", "0%").attr("stop-color", "rgba(45, 35, 25, 0.98)")
    finalGradient.append("stop").attr("offset", "100%").attr("stop-color", "rgba(30, 25, 20, 0.98)")

    const content = svg.append("g").attr("class", "bracket-content")

    this.connectorsLayer = content.append("g").attr("class", "connectors-layer")
    this.matchesLayer = content.append("g").attr("class", "matches-layer")
    this.labelsLayer = content.append("g").attr("class", "labels-layer")
    this.trophyLayer = content.append("g").attr("class", "trophy-layer")

    if (!this.isMobile) {
      this.renderConnectors()
    } else {
      this.renderMobileConnectors()
    }
    this.renderMatches()
    this.renderRoundLabels()
    if (!this.isMobile) {
      this.renderTrophy()
    }
  }

  renderConnectors() {
    const connectors = []

    Object.entries(this.constructor.PROGRESSION).forEach(([dest, sources]) => {
      const destPos = this.matchPositions.get(parseInt(dest))
      if (!destPos) return

      sources.forEach((src, idx) => {
        const srcPos = this.matchPositions.get(src)
        if (!srcPos) return

        const isRightSide = src >= 57 && src <= 64 || src >= 69 && src <= 72 || src === 75 || src === 76 || src === 78

        connectors.push({
          from: src,
          to: parseInt(dest),
          path: this.createConnectorPath(srcPos, destPos, isRightSide, idx),
          teamId: this.getWinnerOfMatch(src)
        })
      })
    })

    this.connectorsLayer.selectAll("path.connector")
      .data(connectors)
      .join("path")
      .attr("class", "connector")
      .attr("d", d => d.path)
      .attr("data-from", d => d.from)
      .attr("data-to", d => d.to)
      .attr("data-team-id", d => d.teamId)
      .attr("fill", "none")
      .attr("stroke", "url(#connectorGradient)")
      .attr("stroke-width", 2)
      .attr("stroke-linecap", "round")
      .style("opacity", 0)
  }

  createConnectorPath(from, to, isRightSide, slotIndex) {
    const startX = isRightSide ? from.x : from.x + from.width
    const startY = from.y + from.height / 2
    const endX = isRightSide ? to.x + to.width : to.x
    const endY = to.y + (slotIndex === 0 ? to.height * 0.3 : to.height * 0.7)

    const midX = (startX + endX) / 2

    return `M ${startX} ${startY} C ${midX} ${startY}, ${midX} ${endY}, ${endX} ${endY}`
  }

  renderMobileConnectors() {
    // Horizontal connectors for mobile bracket (like desktop but smaller)
    const connectors = []

    // Left bracket connectors (going right)
    const r32Left = this.constructor.ROUNDS.round_of_32.left
    const r16Left = this.constructor.ROUNDS.round_of_16.left
    const qfLeft = this.constructor.ROUNDS.quarter_final.left
    const sfLeft = this.constructor.ROUNDS.semi_final.left

    // R32 -> R16 left
    r16Left.forEach((r16Match, i) => {
      connectors.push(...this.createHorizontalConnectorPair(r32Left[i * 2], r32Left[i * 2 + 1], r16Match, 'right'))
    })

    // R16 -> QF left
    qfLeft.forEach((qfMatch, i) => {
      connectors.push(...this.createHorizontalConnectorPair(r16Left[i * 2], r16Left[i * 2 + 1], qfMatch, 'right'))
    })

    // QF -> SF left
    connectors.push(...this.createHorizontalConnectorPair(qfLeft[0], qfLeft[1], sfLeft[0], 'right'))

    // Right bracket connectors (going left)
    const r32Right = this.constructor.ROUNDS.round_of_32.right
    const r16Right = this.constructor.ROUNDS.round_of_16.right
    const qfRight = this.constructor.ROUNDS.quarter_final.right
    const sfRight = this.constructor.ROUNDS.semi_final.right

    // R32 -> R16 right
    r16Right.forEach((r16Match, i) => {
      connectors.push(...this.createHorizontalConnectorPair(r32Right[i * 2], r32Right[i * 2 + 1], r16Match, 'left'))
    })

    // R16 -> QF right
    qfRight.forEach((qfMatch, i) => {
      connectors.push(...this.createHorizontalConnectorPair(r16Right[i * 2], r16Right[i * 2 + 1], qfMatch, 'left'))
    })

    // QF -> SF right
    connectors.push(...this.createHorizontalConnectorPair(qfRight[0], qfRight[1], sfRight[0], 'left'))

    // SF -> Final (both sides go down to final)
    connectors.push(...this.createSFToFinalConnector(sfLeft[0], sfRight[0], 80))

    this.connectorsLayer.selectAll("path.connector")
      .data(connectors)
      .join("path")
      .attr("class", "connector")
      .attr("d", d => d.path)
      .attr("fill", "none")
      .attr("stroke", "rgba(196, 167, 125, 0.4)")
      .attr("stroke-width", 1.5)
      .attr("stroke-linecap", "round")
      .style("opacity", 0)
  }

  createHorizontalConnectorPair(src1Num, src2Num, destNum, direction) {
    const src1 = this.matchPositions.get(src1Num)
    const src2 = this.matchPositions.get(src2Num)
    const dest = this.matchPositions.get(destNum)

    if (!src1 || !src2 || !dest) return []

    const connectors = []

    // Direction determines which side connectors come from/go to
    const src1StartX = direction === 'right' ? src1.x + src1.width : src1.x
    const src2StartX = direction === 'right' ? src2.x + src2.width : src2.x
    const destEndX = direction === 'right' ? dest.x : dest.x + dest.width

    const src1Y = src1.y + src1.height / 2
    const src2Y = src2.y + src2.height / 2
    const destTopY = dest.y + dest.height * 0.3
    const destBotY = dest.y + dest.height * 0.7

    const midX = (src1StartX + destEndX) / 2

    // Connector from src1 to dest top slot
    connectors.push({
      path: `M ${src1StartX} ${src1Y} L ${midX} ${src1Y} L ${midX} ${destTopY} L ${destEndX} ${destTopY}`
    })

    // Connector from src2 to dest bottom slot
    connectors.push({
      path: `M ${src2StartX} ${src2Y} L ${midX} ${src2Y} L ${midX} ${destBotY} L ${destEndX} ${destBotY}`
    })

    return connectors
  }

  createSFToFinalConnector(sfLeftNum, sfRightNum, finalNum) {
    const sfLeft = this.matchPositions.get(sfLeftNum)
    const sfRight = this.matchPositions.get(sfRightNum)
    const final = this.matchPositions.get(finalNum)

    if (!sfLeft || !sfRight || !final) return []

    const connectors = []

    // Left SF goes right then down to final
    const leftStartX = sfLeft.x + sfLeft.width
    const leftStartY = sfLeft.y + sfLeft.height / 2
    const finalLeftX = final.x
    const finalY = final.y + final.height / 2

    connectors.push({
      path: `M ${leftStartX} ${leftStartY} L ${finalLeftX - 10} ${leftStartY} L ${finalLeftX - 10} ${finalY} L ${finalLeftX} ${finalY}`
    })

    // Right SF goes left then down to final
    const rightStartX = sfRight.x
    const rightStartY = sfRight.y + sfRight.height / 2
    const finalRightX = final.x + final.width

    connectors.push({
      path: `M ${rightStartX} ${rightStartY} L ${finalRightX + 10} ${rightStartY} L ${finalRightX + 10} ${finalY} L ${finalRightX} ${finalY}`
    })

    return connectors
  }

  renderMatches() {
    const matchData = Array.from(this.matchPositions.entries()).map(([num, pos]) => ({
      matchNumber: num,
      ...pos,
      match: this.matches.get(num)
    }))

    const matchGroups = this.matchesLayer.selectAll("g.match-group")
      .data(matchData, d => d.matchNumber)
      .join("g")
      .attr("class", d => `match-group ${d.isFinal ? 'final' : ''} ${d.isThirdPlace ? 'third-place' : ''}`)
      .attr("transform", d => `translate(${d.x}, ${d.y})`)
      .attr("data-match-number", d => d.matchNumber)
      .style("opacity", 0)
      .style("cursor", "pointer")
      .on("mouseenter", (event, d) => this.handleMatchHover(event, d))
      .on("mouseleave", (event, d) => this.handleMatchLeave(event, d))
      .on("click", (event, d) => this.handleMatchClick(event, d))

    // Match background
    matchGroups.append("rect")
      .attr("class", "match-bg")
      .attr("width", d => d.width)
      .attr("height", d => d.height)
      .attr("rx", this.isMobile ? 6 : 10)
      .attr("fill", d => d.isFinal ? "url(#finalGradient)" : "rgba(26, 26, 26, 0.95)")
      .attr("stroke", d => d.isFinal ? "rgba(196, 167, 125, 0.5)" : "rgba(196, 167, 125, 0.2)")
      .attr("stroke-width", d => d.isFinal ? 2 : 1)

    // Match number badge - hidden on mobile
    if (!this.isMobile) {
      matchGroups.append("text")
        .attr("class", "match-number")
        .attr("x", d => d.width - 10)
        .attr("y", 16)
        .attr("text-anchor", "end")
        .attr("fill", "rgba(196, 167, 125, 0.5)")
        .attr("font-size", "11px")
        .attr("font-family", "var(--font-body)")
        .text(d => `#${d.matchNumber}`)
    }

    const teamsGroup = matchGroups.append("g").attr("class", "teams")

    this.renderTeamRow(teamsGroup, "home", 0)

    // Divider
    matchGroups.append("line")
      .attr("x1", 10)
      .attr("x2", d => d.width - 10)
      .attr("y1", d => d.height / 2)
      .attr("y2", d => d.height / 2)
      .attr("stroke", "rgba(196, 167, 125, 0.15)")
      .attr("stroke-width", 1)

    this.renderTeamRow(teamsGroup, "away", 1)
  }

  renderTeamRow(container, type, index) {
    const rowHeight = this.isMobile ? 27 : 44
    const yOffset = index * rowHeight + (index === 1 ? 1 : 0) // Small extra gap for away team

    const teamRows = container.append("g")
      .attr("class", d => {
        const match = d.match
        const team = type === "home" ? match?.homeTeam : match?.awayTeam
        const winner = this.getWinnerOfMatch(d.matchNumber)
        const isWinner = team && winner === team.id
        const prediction = this.predictions[match?.id]
        const hasResult = prediction?.homeScore != null && prediction?.awayScore != null

        let classes = `team-row team-${type}`
        if (isWinner) classes += " winner"
        if (!team) classes += " tbd"
        if (this.quickMode && match?.teamsKnown && !hasResult) classes += " clickable"
        return classes
      })
      .attr("transform", `translate(0, ${yOffset})`)
      .attr("data-team-id", d => {
        const match = d.match
        return type === "home" ? match?.homeTeam?.id : match?.awayTeam?.id
      })
      .attr("data-team-type", type)
      .on("click", (event, d) => {
        event.stopPropagation()
        this.handleTeamClick(event, d, type)
      })

    // Team row background
    teamRows.append("rect")
      .attr("class", "team-bg")
      .attr("x", 0)
      .attr("y", 0)
      .attr("width", d => d.width)
      .attr("height", rowHeight)
      .attr("fill", "transparent")

    // Flag - centered on mobile (no name), with name on desktop
    teamRows.append("text")
      .attr("class", "team-flag")
      .attr("x", this.isMobile ? d => d.width / 2 : 14)
      .attr("y", rowHeight / 2 + 5)
      .attr("text-anchor", this.isMobile ? "middle" : "start")
      .attr("font-size", this.isMobile ? "18px" : "16px")
      .style("opacity", d => {
        const match = d.match
        const team = type === "home" ? match?.homeTeam : match?.awayTeam
        return team ? 1 : 0.3
      })
      .text(d => {
        const match = d.match
        const team = type === "home" ? match?.homeTeam : match?.awayTeam
        return team ? this.getFlagEmoji(team.isoCode) : "🏳️"
      })

    // Team name - ONLY on desktop (hidden on mobile)
    if (!this.isMobile) {
      teamRows.append("text")
        .attr("class", "team-name")
        .attr("x", 38)
        .attr("y", rowHeight / 2 + 5)
        .attr("fill", d => {
          const match = d.match
          const team = type === "home" ? match?.homeTeam : match?.awayTeam
          return team ? "var(--color-cream)" : "var(--color-slate)"
        })
        .attr("font-size", "14px")
        .attr("font-family", "var(--font-body)")
        .attr("font-weight", "500")
        .text(d => {
          const match = d.match
          const team = type === "home" ? match?.homeTeam : match?.awayTeam
          if (team) {
            const maxLen = 14
            return team.name.length > maxLen ? team.name.substring(0, maxLen - 1) + "…" : team.name
          }
          return "TBD"
        })
    }

    // Score (complete mode) - hidden on mobile (just flags)
    if (!this.quickMode && !this.isMobile) {
      teamRows.append("text")
        .attr("class", "team-score")
        .attr("x", d => d.width - 14)
        .attr("y", rowHeight / 2 + 6)
        .attr("text-anchor", "end")
        .attr("fill", "var(--color-gold)")
        .attr("font-size", "16px")
        .attr("font-family", "var(--font-display)")
        .attr("font-weight", "600")
        .text(d => {
          const match = d.match
          const prediction = this.predictions[match?.id]
          if (!prediction) return ""
          return type === "home" ? prediction.homeScore ?? "" : prediction.awayScore ?? ""
        })
    }

    // Winner indicator - green background on mobile, checkmark on desktop
    if (this.quickMode) {
      if (this.isMobile) {
        // On mobile: highlight the winner row with a green tint
        teamRows.select(".team-bg")
          .attr("fill", d => {
            const match = d.match
            const team = type === "home" ? match?.homeTeam : match?.awayTeam
            const winner = this.getWinnerOfMatch(d.matchNumber)
            return team && winner === team.id ? "rgba(61, 107, 79, 0.4)" : "transparent"
          })
      } else {
        // On desktop: checkmark
        teamRows.append("text")
          .attr("class", "winner-check")
          .attr("x", d => d.width - 14)
          .attr("y", rowHeight / 2 + 6)
          .attr("text-anchor", "end")
          .attr("fill", "var(--color-success)")
          .attr("font-size", "16px")
          .style("opacity", d => {
            const match = d.match
            const team = type === "home" ? match?.homeTeam : match?.awayTeam
            const winner = this.getWinnerOfMatch(d.matchNumber)
            return team && winner === team.id ? 1 : 0
          })
          .text("✓")
      }
    }
  }

  renderRoundLabels() {
    if (this.isMobile && this.mobileRoundLabels) {
      this.labelsLayer.selectAll("text.round-label")
        .data(this.mobileRoundLabels)
        .join("text")
        .attr("class", "round-label")
        .attr("x", d => d.x)
        .attr("y", d => d.y)
        .attr("text-anchor", "middle")
        .attr("fill", "var(--color-gold)")
        .attr("font-size", "11px")
        .attr("font-family", "var(--font-display)")
        .attr("font-weight", "600")
        .attr("letter-spacing", "0.05em")
        .attr("text-transform", "uppercase")
        .text(d => d.name)
      return
    }

    const labels = [
      { text: "R32", x: this.matchPositions.get(49).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "R16", x: this.matchPositions.get(65).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "QF", x: this.matchPositions.get(73).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "SF", x: this.matchPositions.get(77).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "FINAL", x: this.matchPositions.get(80).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "SF", x: this.matchPositions.get(78).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "QF", x: this.matchPositions.get(75).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "R16", x: this.matchPositions.get(69).x + this.constructor.MATCH_WIDTH / 2 },
      { text: "R32", x: this.matchPositions.get(57).x + this.constructor.MATCH_WIDTH / 2 }
    ]

    this.labelsLayer.selectAll("text.round-label")
      .data(labels)
      .join("text")
      .attr("class", "round-label")
      .attr("x", d => d.x)
      .attr("y", 18)
      .attr("text-anchor", "middle")
      .attr("fill", "var(--color-bronze-light)")
      .attr("font-size", "12px")
      .attr("font-family", "var(--font-body)")
      .attr("font-weight", "600")
      .attr("letter-spacing", "0.1em")
      .text(d => d.text)
  }

  renderTrophy() {
    if (this.isMobile) return // No trophy on mobile

    const trophy = this.trophyLayer.append("g")
      .attr("class", "trophy")
      .attr("transform", `translate(${this.trophyPosition.x}, ${this.trophyPosition.y})`)

    trophy.append("circle")
      .attr("class", "trophy-glow")
      .attr("r", 25)
      .attr("fill", "rgba(196, 167, 125, 0.1)")

    trophy.append("text")
      .attr("class", "trophy-icon")
      .attr("text-anchor", "middle")
      .attr("dominant-baseline", "middle")
      .attr("font-size", "28px")
      .text("🏆")
  }

  // ==================== INTERACTIONS ====================

  handleMatchHover(event, d) {
    const svg = d3.select(this.svgTarget)
    const matchGroup = svg.select(`[data-match-number="${d.matchNumber}"]`)

    matchGroup.select(".match-bg")
      .transition()
      .duration(150)
      .attr("stroke", "var(--color-gold)")
      .attr("stroke-width", 2)
  }

  handleMatchLeave(event, d) {
    const svg = d3.select(this.svgTarget)
    const matchGroup = svg.select(`[data-match-number="${d.matchNumber}"]`)

    matchGroup.select(".match-bg")
      .transition()
      .duration(150)
      .attr("stroke", d.isFinal ? "rgba(196, 167, 125, 0.5)" : "rgba(196, 167, 125, 0.2)")
      .attr("stroke-width", d.isFinal ? 2 : 1)

    this.clearTeamHighlight()
  }

  handleMatchClick(event, d) {
    if (this.quickMode) return

    const match = d.match
    if (!match?.teamsKnown) return

    const url = this.knockoutPathValue.replace("__MATCH__", d.matchNumber)
    window.Turbo.visit(url)
  }

  handleTeamClick(event, d, type) {
    if (!this.quickMode) return

    const match = d.match
    if (!match?.teamsKnown) return

    const prediction = this.predictions[match.id]
    if (prediction?.homeScore != null) return

    const team = type === "home" ? match.homeTeam : match.awayTeam
    if (!team) return

    event.preventDefault()
    event.stopPropagation()

    this.selectWinner(d.matchNumber, team.id)
  }

  selectWinner(matchNumber, teamId) {
    const url = this.quickWinnerPathValue
      .replace("__MATCH__", matchNumber)
      .replace("__TEAM__", teamId)

    // Find next match to center on after selection
    const nextMatchNumber = this.findNextMatchAfter(matchNumber)

    // Store update info for post-refresh animation
    window._bracketUpdate = {
      matchNumber: matchNumber,
      winnerId: teamId,
      nextMatchNumber: nextMatchNumber
    }

    // Also store for mobile centering
    if (this.isMobile && nextMatchNumber) {
      window._nextMatchToCenter = nextMatchNumber
    }

    fetch(url, {
      method: "PATCH",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      }
    })
      .then(response => {
        if (!response.ok) throw new Error("Failed to set winner")
        return response.text()
      })
      .then(html => {
        window.Turbo.renderStreamMessage(html)
      })
      .catch(error => {
        console.error("Error selecting winner:", error)
        window._bracketUpdate = null
      })
  }

  // Find the next match that the winner of this match will play in
  findNextMatchAfter(matchNumber) {
    // Use PROGRESSION to find where winner goes
    for (const [dest, sources] of Object.entries(this.constructor.PROGRESSION)) {
      if (sources.includes(matchNumber)) {
        return parseInt(dest)
      }
    }
    return null
  }

  highlightTeamPath(teamId) {
    const svg = d3.select(this.svgTarget)

    svg.selectAll(".match-group").classed("dimmed", true)

    svg.selectAll(".team-row").each((d, i, nodes) => {
      const row = d3.select(nodes[i])
      if (row.attr("data-team-id") == teamId) {
        const matchGroup = d3.select(nodes[i].closest(".match-group"))
        matchGroup.classed("dimmed", false).classed("highlighted", true)
      }
    })

    svg.selectAll(".connector")
      .classed("dimmed", true)
      .filter(function () {
        return d3.select(this).attr("data-team-id") == teamId
      })
      .classed("dimmed", false)
      .classed("highlighted", true)
      .attr("stroke", "var(--color-gold)")
      .attr("stroke-width", 3)
  }

  clearTeamHighlight() {
    const svg = d3.select(this.svgTarget)

    svg.selectAll(".match-group")
      .classed("dimmed", false)
      .classed("highlighted", false)

    svg.selectAll(".connector")
      .classed("dimmed", false)
      .classed("highlighted", false)
      .attr("stroke", "url(#connectorGradient)")
      .attr("stroke-width", 2)
  }

  // ==================== ANIMATIONS ====================

  animateEntrance() {
    const svg = d3.select(this.svgTarget)

    // Check if this is an update after selecting a winner
    const update = window._bracketUpdate
    if (update) {
      window._bracketUpdate = null
      this.animateUpdate(update)
      return
    }

    // Initial page load - show everything immediately, no stagger
    svg.selectAll(".match-group")
      .style("opacity", 1)

    svg.selectAll(".connector")
      .style("opacity", 1)

    svg.select(".trophy")
      .style("opacity", 1)
  }

  animateUpdate(update) {
    const svg = d3.select(this.svgTarget)

    // Show everything immediately
    svg.selectAll(".match-group").style("opacity", 1)
    svg.selectAll(".connector").style("opacity", 1)

    // Flash the match that was just decided
    const decidedMatch = svg.select(`[data-match-number="${update.matchNumber}"]`)
    if (decidedMatch.size()) {
      // Brief highlight effect
      decidedMatch.select(".match-bg")
        .attr("stroke", "var(--color-success)")
        .attr("stroke-width", 3)
        .transition()
        .duration(400)
        .attr("stroke", "rgba(196, 167, 125, 0.2)")
        .attr("stroke-width", 1)
    }

    // Animate the next match where the winner advances (fade in effect)
    if (update.nextMatchNumber) {
      const nextMatch = svg.select(`[data-match-number="${update.nextMatchNumber}"]`)
      if (nextMatch.size()) {
        nextMatch
          .style("opacity", 0)
          .style("transform", "scale(0.95)")
          .transition()
          .duration(300)
          .ease(d3.easeCubicOut)
          .style("opacity", 1)
          .style("transform", "scale(1)")

        // Highlight the new team appearing
        nextMatch.select(".match-bg")
          .attr("stroke", "var(--color-gold)")
          .attr("stroke-width", 2)
          .transition()
          .delay(300)
          .duration(400)
          .attr("stroke", "rgba(196, 167, 125, 0.2)")
          .attr("stroke-width", 1)
      }
    }
  }

  showChampionCelebration() {
    if (this.hasChampionOverlayTarget) {
      this.championOverlayTarget.classList.add("visible")
      // Auto-hide after 2 seconds
      setTimeout(() => {
        this.championOverlayTarget.classList.remove("visible")
      }, 2000)
    }

    const svg = d3.select(this.svgTarget)
    svg.select(".trophy-glow")
      .transition()
      .duration(400)
      .ease(d3.easeQuadInOut)
      .attr("r", 40)
      .attr("fill", "rgba(196, 167, 125, 0.2)")
      .transition()
      .duration(300)
      .attr("r", 30)
      .attr("fill", "rgba(196, 167, 125, 0.1)")

    this.launchConfetti()

    // Highlight champion's path quickly
    setTimeout(() => {
      this.highlightTeamPath(this.championId)
    }, 500)
  }

  launchConfetti() {
    if (!this.hasConfettiTarget) return

    const canvas = this.confettiTarget
    const ctx = canvas.getContext("2d")

    canvas.width = canvas.offsetWidth
    canvas.height = canvas.offsetHeight

    const colors = ["#c4a77d", "#d4bc96", "#f5f2eb", "#8b7355", "#3d6b4f"]
    const particles = []

    // Fewer particles for faster animation
    for (let i = 0; i < 60; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: -20,
        vx: (Math.random() - 0.5) * 6,
        vy: Math.random() * 5 + 4,
        color: colors[Math.floor(Math.random() * colors.length)],
        size: Math.random() * 6 + 3,
        rotation: Math.random() * 360,
        rotationSpeed: (Math.random() - 0.5) * 15
      })
    }

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)

      let activeParticles = 0

      particles.forEach(p => {
        if (p.y < canvas.height + 20) {
          activeParticles++

          p.x += p.vx
          p.y += p.vy
          p.vy += 0.15
          p.rotation += p.rotationSpeed

          ctx.save()
          ctx.translate(p.x, p.y)
          ctx.rotate((p.rotation * Math.PI) / 180)
          ctx.fillStyle = p.color
          ctx.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2)
          ctx.restore()
        }
      })

      if (activeParticles > 0) {
        requestAnimationFrame(animate)
      } else {
        ctx.clearRect(0, 0, canvas.width, canvas.height)
      }
    }

    animate()
  }

  // ==================== ZOOM (MOBILE ONLY) ====================

  setupZoom() {
    if (!this.isMobile) return // Desktop: no zoom

    const svg = d3.select(this.svgTarget)
    const content = svg.select(".bracket-content")

    this.zoom = d3.zoom()
      .scaleExtent([0.4, 2])
      .on("zoom", (event) => {
        content.attr("transform", event.transform)
        this.currentZoom = event.transform
      })

    svg.call(this.zoom)

    // Double-tap to reset
    svg.on("dblclick.zoom", () => {
      svg.transition()
        .duration(300)
        .call(this.zoom.transform, d3.zoomIdentity)
    })

    // Initial zoom to fit and center on first matches
    setTimeout(() => {
      this.centerOnNextMatch()
    }, 500)
  }

  zoomIn() {
    if (!this.isMobile || !this.zoom) return
    const svg = d3.select(this.svgTarget)
    svg.transition().duration(200).call(this.zoom.scaleBy, 1.4)
  }

  zoomOut() {
    if (!this.isMobile || !this.zoom) return
    const svg = d3.select(this.svgTarget)
    svg.transition().duration(200).call(this.zoom.scaleBy, 0.7)
  }

  zoomReset() {
    if (!this.isMobile || !this.zoom) return
    const svg = d3.select(this.svgTarget)
    svg.transition().duration(300).call(this.zoom.transform, d3.zoomIdentity)
  }

  // Center view on a specific match
  centerOnMatch(matchNumber) {
    if (!this.isMobile || !this.zoom) return

    const pos = this.matchPositions.get(matchNumber)
    if (!pos) return

    const svg = d3.select(this.svgTarget)
    const svgNode = svg.node()
    const { width: svgWidth, height: svgHeight } = svgNode.getBoundingClientRect()

    // Calculate transform to center on match
    const scale = 1.2
    const x = svgWidth / 2 - (pos.x + pos.width / 2) * scale
    const y = svgHeight / 2 - (pos.y + pos.height / 2) * scale

    const transform = d3.zoomIdentity.translate(x, y).scale(scale)

    svg.transition()
      .duration(500)
      .ease(d3.easeCubicInOut)
      .call(this.zoom.transform, transform)
  }

  // Find and center on next playable match
  centerOnNextMatch() {
    if (!this.isMobile) return

    // Find first match that has teams but no result
    const roundOrder = ['round_of_32', 'round_of_16', 'quarter_final', 'semi_final', 'final']

    for (const round of roundOrder) {
      const roundConfig = this.constructor.ROUNDS[round]
      const allMatches = [
        ...(roundConfig.left || []),
        ...(roundConfig.right || []),
        ...(roundConfig.center || [])
      ]

      for (const matchNum of allMatches) {
        const match = this.matches.get(matchNum)
        if (!match) continue

        const prediction = this.predictions[match.id]
        const hasResult = prediction?.homeScore != null && prediction?.awayScore != null

        if (match.teamsKnown && !hasResult) {
          this.centerOnMatch(matchNum)
          return
        }
      }
    }
  }

  // ==================== TURBO ====================

  setupTurboListeners() {}

  dataValueChanged() {
    if (!this.isConnected) return

    if (this.hasDataValue && this.dataValue.matches) {
      this.initializeBracket()
    }
  }

  // ==================== HELPERS ====================

  getWinnerOfMatch(matchNumber) {
    const match = this.matches.get(matchNumber)
    if (!match) return null

    const prediction = this.predictions[match.id]
    if (!prediction || prediction.homeScore == null || prediction.awayScore == null) {
      return null
    }

    if (prediction.homeScore > prediction.awayScore) {
      return match.homeTeam?.id
    } else if (prediction.awayScore > prediction.homeScore) {
      return match.awayTeam?.id
    }
    return null
  }

  getFlagEmoji(isoCode) {
    if (!isoCode) return "🏳️"

    const code = isoCode.toUpperCase()

    // Special cases for nations without standard ISO 3166-1 alpha-2 codes
    const specialFlags = {
      // UK nations (use subdivision flags)
      'ENG': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',  // England
      'SCO': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',  // Scotland
      'WAL': '🏴󠁧󠁢󠁷󠁬󠁳󠁿',  // Wales
      'NIR': '🇬🇧',           // Northern Ireland (use UK flag)
      // Other special cases
      'UK': '🇬🇧',
      'GB': '🇬🇧',
      'EU': '🇪🇺',
    }

    if (specialFlags[code]) {
      return specialFlags[code]
    }

    // Standard ISO 3166-1 alpha-2 conversion to regional indicator symbols
    // Only works for 2-letter codes
    if (code.length === 2) {
      const codePoints = code
        .split("")
        .map(char => 127397 + char.charCodeAt(0))
      return String.fromCodePoint(...codePoints)
    }

    // For 3-letter codes not in special cases, try first 2 letters
    if (code.length === 3) {
      const twoLetter = code.substring(0, 2)
      const codePoints = twoLetter
        .split("")
        .map(char => 127397 + char.charCodeAt(0))
      return String.fromCodePoint(...codePoints)
    }

    return "🏳️"
  }
}
