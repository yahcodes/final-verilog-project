const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

const W = canvas.width;
const H = canvas.height;

// Game state
let bird, pipes, score, bestScore, gameState, frameCount;

const GRAVITY = 0.45;
const FLAP_POWER = -7.5;
const PIPE_SPEED = 2.5;
const PIPE_GAP = 150;
const PIPE_WIDTH = 60;
const PIPE_SPAWN_INTERVAL = 90;

// Wing animation constants
// wingAngle: degrees from horizontal. Negative = raised (glide), positive = pushed down (flap)
const WING_FLAP_ANGLE = 55;       // how far down the wing snaps on flap
const WING_GLIDE_ANGLE = -20;     // resting glide position (slightly raised)
const WING_RETURN_SPEED = 0.06;   // how fast wing eases back to glide (0-1 lerp factor)
const WING_IDLE_SPEED = 4;        // speed of gentle idle flapping on ready screen
const WING_IDLE_AMPLITUDE = 25;   // amplitude of idle wing bob

function resetGame() {
    bird = {
        x: 80, y: H / 2, w: 34, h: 26,
        vy: 0, rotation: 0,
        wingAngle: WING_GLIDE_ANGLE,  // current wing angle in degrees
    };
    pipes = [];
    score = 0;
    frameCount = 0;
    gameState = "ready"; // ready, playing, dead
}

bestScore = 0;
resetGame();

// Input
function flap() {
    if (gameState === "ready") {
        gameState = "playing";
        bird.vy = FLAP_POWER;
        bird.wingAngle = WING_FLAP_ANGLE;
    } else if (gameState === "playing") {
        bird.vy = FLAP_POWER;
        bird.wingAngle = WING_FLAP_ANGLE;
    } else if (gameState === "dead") {
        resetGame();
    }
}

document.addEventListener("keydown", (e) => {
    if (e.code === "Space" || e.code === "ArrowUp") {
        e.preventDefault();
        flap();
    }
});
canvas.addEventListener("click", flap);
canvas.addEventListener("touchstart", (e) => { e.preventDefault(); flap(); });

// Collision detection
function collides(bx, by, bw, bh, px, py, pw, ph) {
    return bx < px + pw && bx + bw > px && by < py + ph && by + bh > py;
}

// Update
function update() {
    if (gameState !== "playing") return;

    frameCount++;

    // Bird physics
    bird.vy += GRAVITY;
    bird.y += bird.vy;
    bird.rotation = Math.min(bird.vy * 3, 80);

    // Wing animation: ease back toward glide position after a flap
    // The further the wing is from glide angle, the faster it returns (exponential ease)
    bird.wingAngle += (WING_GLIDE_ANGLE - bird.wingAngle) * WING_RETURN_SPEED;
    // When falling fast, raise wings slightly higher (like a bird bracing)
    if (bird.vy > 3) {
        const fallExtra = Math.min((bird.vy - 3) * 2, 15);
        bird.wingAngle += (WING_GLIDE_ANGLE - fallExtra - bird.wingAngle) * 0.03;
    }

    // Spawn pipes
    if (frameCount % PIPE_SPAWN_INTERVAL === 0) {
        const topH = 50 + Math.random() * (H - PIPE_GAP - 150);
        pipes.push({
            x: W,
            topH: topH,
            bottomY: topH + PIPE_GAP,
            scored: false,
        });
    }

    // Move pipes and check collisions
    for (let i = pipes.length - 1; i >= 0; i--) {
        const p = pipes[i];
        p.x -= PIPE_SPEED;

        // Score
        if (!p.scored && p.x + PIPE_WIDTH < bird.x) {
            p.scored = true;
            score++;
        }

        // Remove off-screen pipes
        if (p.x + PIPE_WIDTH < 0) {
            pipes.splice(i, 1);
            continue;
        }

        // Collision with top pipe
        if (collides(bird.x, bird.y, bird.w, bird.h, p.x, 0, PIPE_WIDTH, p.topH)) {
            die();
            return;
        }
        // Collision with bottom pipe
        if (collides(bird.x, bird.y, bird.w, bird.h, p.x, p.bottomY, PIPE_WIDTH, H - p.bottomY)) {
            die();
            return;
        }
    }

    // Floor and ceiling
    if (bird.y + bird.h > H - 80 || bird.y < 0) {
        die();
    }
}

function die() {
    gameState = "dead";
    bird.wingAngle = -35; // wings raised in shock/brace position
    if (score > bestScore) bestScore = score;
}

// Drawing helpers
function drawWing(anchorX, anchorY, angle, scale, color, outlineColor) {
    // Draw a single wing as a multi-segment shape that bends naturally
    const rad = (angle * Math.PI) / 180;
    ctx.save();
    ctx.translate(anchorX, anchorY);
    ctx.rotate(rad);
    ctx.scale(scale, scale);

    // Primary feathers (outer wing)
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.quadraticCurveTo(-6, -2, -20, 2);   // leading edge curves out
    ctx.quadraticCurveTo(-24, 4, -22, 7);    // tip rounds
    ctx.quadraticCurveTo(-16, 9, -8, 6);     // trailing edge feathers
    ctx.quadraticCurveTo(-3, 4, 0, 0);       // back to anchor
    ctx.fill();

    // Outline
    ctx.strokeStyle = outlineColor;
    ctx.lineWidth = 1.2;
    ctx.stroke();

    // Secondary feathers (inner detail)
    ctx.fillStyle = outlineColor;
    ctx.globalAlpha = 0.3;
    ctx.beginPath();
    ctx.moveTo(-3, 2);
    ctx.quadraticCurveTo(-10, 3, -14, 5);
    ctx.quadraticCurveTo(-10, 6, -3, 4);
    ctx.closePath();
    ctx.fill();
    ctx.globalAlpha = 1;

    // Feather line details
    ctx.strokeStyle = outlineColor;
    ctx.globalAlpha = 0.4;
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.moveTo(-6, 2);
    ctx.lineTo(-8, 5);
    ctx.moveTo(-11, 3);
    ctx.lineTo(-13, 6);
    ctx.moveTo(-16, 3);
    ctx.lineTo(-18, 6);
    ctx.stroke();
    ctx.globalAlpha = 1;

    ctx.restore();
}

function drawBird() {
    ctx.save();
    ctx.translate(bird.x + bird.w / 2, bird.y + bird.h / 2);
    ctx.rotate((bird.rotation * Math.PI) / 180);

    // Tail feathers (drawn behind body)
    ctx.fillStyle = "#e6a817";
    ctx.beginPath();
    ctx.moveTo(-14, -2);
    ctx.lineTo(-24, -6);
    ctx.lineTo(-22, 0);
    ctx.lineTo(-24, 6);
    ctx.lineTo(-14, 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = "#c48a10";
    ctx.lineWidth = 1;
    ctx.stroke();

    // Far wing (behind body, slightly muted) - mirrors the near wing
    drawWing(-2, 1, bird.wingAngle * 0.85, 0.75, "#d4920d", "#b87a0a");

    // Body
    ctx.fillStyle = "#f1c40f";
    ctx.beginPath();
    ctx.ellipse(0, 0, bird.w / 2, bird.h / 2, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#e67e22";
    ctx.lineWidth = 2;
    ctx.stroke();

    // Belly highlight
    ctx.fillStyle = "#f7dc6f";
    ctx.beginPath();
    ctx.ellipse(2, 4, bird.w / 3, bird.h / 3.5, 0.1, 0, Math.PI * 2);
    ctx.fill();

    // Eye white
    ctx.fillStyle = "#fff";
    ctx.beginPath();
    ctx.arc(8, -5, 6.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#bbb";
    ctx.lineWidth = 0.8;
    ctx.stroke();

    // Pupil (shifts slightly based on velocity for liveliness)
    const pupilShift = Math.min(Math.max(bird.vy * 0.3, -1.5), 1.5);
    ctx.fillStyle = "#2c3e50";
    ctx.beginPath();
    ctx.arc(9.5, -5 + pupilShift, 3, 0, Math.PI * 2);
    ctx.fill();
    // Pupil shine
    ctx.fillStyle = "#fff";
    ctx.beginPath();
    ctx.arc(10.5, -6 + pupilShift, 1, 0, Math.PI * 2);
    ctx.fill();

    // Beak (two-part for depth)
    ctx.fillStyle = "#e74c3c";
    ctx.beginPath();
    ctx.moveTo(13, -1);
    ctx.lineTo(23, 2);
    ctx.lineTo(13, 3);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = "#c0392b";
    ctx.beginPath();
    ctx.moveTo(13, 3);
    ctx.lineTo(23, 2);
    ctx.lineTo(13, 7);
    ctx.closePath();
    ctx.fill();

    // Near wing (in front of body)
    drawWing(-2, 2, bird.wingAngle, 1.0, "#f39c12", "#d68910");

    ctx.restore();
}

function drawPipe(p) {
    const grad = ctx.createLinearGradient(p.x, 0, p.x + PIPE_WIDTH, 0);
    grad.addColorStop(0, "#27ae60");
    grad.addColorStop(0.5, "#2ecc71");
    grad.addColorStop(1, "#27ae60");

    // Top pipe
    ctx.fillStyle = grad;
    ctx.fillRect(p.x, 0, PIPE_WIDTH, p.topH);
    // Top pipe cap
    ctx.fillStyle = "#229954";
    ctx.fillRect(p.x - 4, p.topH - 25, PIPE_WIDTH + 8, 25);
    ctx.strokeStyle = "#1e8449";
    ctx.lineWidth = 2;
    ctx.strokeRect(p.x - 4, p.topH - 25, PIPE_WIDTH + 8, 25);

    // Bottom pipe
    ctx.fillStyle = grad;
    ctx.fillRect(p.x, p.bottomY, PIPE_WIDTH, H - p.bottomY);
    // Bottom pipe cap
    ctx.fillStyle = "#229954";
    ctx.fillRect(p.x - 4, p.bottomY, PIPE_WIDTH + 8, 25);
    ctx.strokeStyle = "#1e8449";
    ctx.lineWidth = 2;
    ctx.strokeRect(p.x - 4, p.bottomY, PIPE_WIDTH + 8, 25);
}

function drawGround() {
    ctx.fillStyle = "#d4a56a";
    ctx.fillRect(0, H - 80, W, 80);
    ctx.fillStyle = "#27ae60";
    ctx.fillRect(0, H - 80, W, 15);

    // Ground detail lines
    ctx.strokeStyle = "#c19a5b";
    ctx.lineWidth = 1;
    for (let i = 0; i < W; i += 30) {
        const offset = gameState === "playing" ? (frameCount * PIPE_SPEED) % 30 : 0;
        ctx.beginPath();
        ctx.moveTo(i - offset, H - 60);
        ctx.lineTo(i - offset + 15, H - 45);
        ctx.stroke();
    }
}

function drawBackground() {
    // Sky gradient
    const sky = ctx.createLinearGradient(0, 0, 0, H - 80);
    sky.addColorStop(0, "#87CEEB");
    sky.addColorStop(1, "#E0F6FF");
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, W, H - 80);

    // Clouds
    ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
    const cloudOffset = gameState === "playing" ? (frameCount * 0.3) % (W + 100) : 0;
    drawCloud(100 - cloudOffset + W, 80);
    drawCloud(300 - cloudOffset + W, 150);
    drawCloud(180 - cloudOffset + W, 50);
}

function drawCloud(x, y) {
    x = ((x % (W + 100)) + W + 100) % (W + 100) - 50;
    ctx.beginPath();
    ctx.arc(x, y, 20, 0, Math.PI * 2);
    ctx.arc(x + 15, y - 10, 15, 0, Math.PI * 2);
    ctx.arc(x + 30, y, 20, 0, Math.PI * 2);
    ctx.arc(x + 15, y + 5, 12, 0, Math.PI * 2);
    ctx.fill();
}

function drawScore() {
    ctx.fillStyle = "#fff";
    ctx.strokeStyle = "#2c3e50";
    ctx.lineWidth = 4;
    ctx.font = "bold 48px Arial";
    ctx.textAlign = "center";
    ctx.strokeText(score, W / 2, 60);
    ctx.fillText(score, W / 2, 60);
}

function drawReadyScreen() {
    ctx.fillStyle = "#fff";
    ctx.strokeStyle = "#2c3e50";
    ctx.lineWidth = 3;

    ctx.font = "bold 42px Arial";
    ctx.textAlign = "center";
    ctx.strokeText("Flappy Bird", W / 2, H / 2 - 80);
    ctx.fillText("Flappy Bird", W / 2, H / 2 - 80);

    ctx.font = "20px Arial";
    ctx.lineWidth = 2;
    ctx.strokeText("Click or press Space to start", W / 2, H / 2 - 30);
    ctx.fillText("Click or press Space to start", W / 2, H / 2 - 30);

    // Bouncing bird hint with idle wing flapping
    const t = Date.now() / 300;
    const bounce = Math.sin(t) * 10;
    bird.y = H / 2 + 30 + bounce;
    bird.wingAngle = Math.sin(t * WING_IDLE_SPEED) * WING_IDLE_AMPLITUDE;
}

function drawDeadScreen() {
    // Overlay
    ctx.fillStyle = "rgba(0, 0, 0, 0.4)";
    ctx.fillRect(0, 0, W, H);

    // Score panel
    ctx.fillStyle = "#DEB887";
    ctx.strokeStyle = "#8B7355";
    ctx.lineWidth = 3;
    const panelW = 250;
    const panelH = 160;
    const panelX = (W - panelW) / 2;
    const panelY = (H - panelH) / 2 - 20;
    ctx.fillRect(panelX, panelY, panelW, panelH);
    ctx.strokeRect(panelX, panelY, panelW, panelH);

    ctx.fillStyle = "#fff";
    ctx.strokeStyle = "#2c3e50";
    ctx.lineWidth = 3;
    ctx.font = "bold 32px Arial";
    ctx.textAlign = "center";
    ctx.strokeText("Game Over", W / 2, panelY + 40);
    ctx.fillText("Game Over", W / 2, panelY + 40);

    ctx.font = "22px Arial";
    ctx.lineWidth = 2;
    ctx.fillStyle = "#4a3520";
    ctx.fillText("Score: " + score, W / 2, panelY + 80);
    ctx.fillText("Best: " + bestScore, W / 2, panelY + 110);

    ctx.font = "18px Arial";
    ctx.fillStyle = "#fff";
    ctx.strokeStyle = "#2c3e50";
    ctx.strokeText("Click to restart", W / 2, panelY + panelH + 40);
    ctx.fillText("Click to restart", W / 2, panelY + panelH + 40);
}

// Main loop
function gameLoop() {
    update();

    drawBackground();
    drawGround();
    pipes.forEach(drawPipe);
    drawBird();

    if (gameState === "playing") {
        drawScore();
    } else if (gameState === "ready") {
        drawReadyScreen();
    } else if (gameState === "dead") {
        drawScore();
        drawDeadScreen();
    }

    requestAnimationFrame(gameLoop);
}

gameLoop();
