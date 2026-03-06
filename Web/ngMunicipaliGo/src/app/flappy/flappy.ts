import { CommonModule } from '@angular/common';
import { Component, ElementRef, ViewChild, AfterViewInit, HostListener, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-flappy',
  standalone: true,
  imports: [CommonModule],
  template: `
<div class="overlay">
  <button class="close" (click)="closeGame()">✕</button>

  <div class="game-container">
    <canvas #gameCanvas width="400" height="600"></canvas>

    <button 
      *ngIf="gameOver" 
      class="restart-btn" 
      (click)="restartGame()">
      Restart
    </button>
  </div>
</div>
`,
  styles: [`

    .game-container {
  position: relative;
  width: 400px;
  height: 600px;
}
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.85);
  display:flex;
  justify-content:center;
  align-items:center;
  z-index:10000;
}
canvas {
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.5);
}

.restart-btn {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  padding: 12px 24px;
  font-size: 18px;
  border-radius: 8px;
  border: none;
  background: #ffcc00;
  cursor: pointer;
  font-weight: bold;
}

.close {
  position:absolute;
  top:20px;
  right:30px;
  font-size:24px;
  background:none;
  border:none;
  color:white;
  cursor:pointer;
}
`]
})
export class FlappyComponent implements AfterViewInit {

  @ViewChild('gameCanvas', { static: true })
  canvasRef!: ElementRef<HTMLCanvasElement>;

  ctx!: CanvasRenderingContext2D;
  pipeInterval: any;
  birdImg = new Image();
  pipeTopImg = new Image();
  pipeBottomImg = new Image();
  bgImg = new Image();

  bird = {
    x: 80,
    y: 300,
    width: 70,
    height: 70,
    velocity: 0
  };

  gravity = 0.5;
  jumpStrength = -8;

  pipes: any[] = [];
  pipeWidth = 60;
  pipeGap = 125;
  pipeSpeed = 2;

  score = 0;
  gameOver = false;
  birdRadius = 12;

  ngAfterViewInit() {
    this.ctx = this.canvasRef.nativeElement.getContext('2d')!;

    this.birdImg.src = '/assets/max.png';
    this.pipeTopImg.src = '/assets/pipe.png';
    this.pipeBottomImg.src = '/assets/pipe.png';
    this.bgImg.src = '/assets/Longueuil_2011.jpg';


    this.startSpawning();
    this.gameLoop();
  }

  restartGame() {
    this.bird.y = 300;
    this.bird.velocity = 0;

    this.pipes = [];
    this.score = 0;
    this.gameOver = false;

    clearInterval(this.pipeInterval);
    this.startSpawning();
  }

  @Output() close = new EventEmitter<void>();

  closeGame() {
    this.close.emit();
  }

  @HostListener('window:keydown', ['$event'])
  handleEsc(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      this.closeGame();
    }
  }

  // Jump on space or click
  @HostListener('window:keydown', ['$event'])
  handleKey(event: KeyboardEvent) {
    if (event.code === 'Space') {
      this.jump();
    }
  }

  @HostListener('window:click')
  handleClick() {
    this.jump();
  }

  jump() {
    if (!this.gameOver) {
      this.bird.velocity = this.jumpStrength;
    }
  }

  startSpawning() {
    this.pipeInterval = setInterval(() => {
      const topHeight = Math.random() * 300 + 50;

      this.pipes.push({
        x: 400,
        topHeight,
        bottomY: topHeight + this.pipeGap
      });
    }, 2000);
  }

  update() {
    if (this.gameOver) return;

    // Bird physics
    this.bird.velocity += this.gravity;
    this.bird.y += this.bird.velocity;

    // Move pipes
    this.pipes.forEach(pipe => {
      pipe.x -= this.pipeSpeed;

      // Score
      if (pipe.x + this.pipeWidth === this.bird.x) {
        this.score++;
      }

      // --- CIRCLE COLLISION ---
      const centerX = this.bird.x + this.bird.width / 2;
      const centerY = this.bird.y + this.bird.height / 2;

      const pipeLeft = pipe.x;
      const pipeRight = pipe.x + this.pipeWidth;

      const collidesHorizontally =
        centerX + this.birdRadius > pipeLeft &&
        centerX - this.birdRadius < pipeRight;

      if (collidesHorizontally) {
        if (
          centerY - this.birdRadius < pipe.topHeight ||
          centerY + this.birdRadius > pipe.bottomY
        ) {
          this.gameOver = true;
        }
      }
    });

    // Ground / ceiling collision
    if (this.bird.y + this.bird.height > 600 || this.bird.y < 0) {
      this.gameOver = true;
    }

    // Remove off-screen pipes
    this.pipes = this.pipes.filter(pipe => pipe.x + this.pipeWidth > 0);
  }

  draw() {
    // Always clear first
    this.ctx.clearRect(0, 0, 400, 600);

    // 1️⃣ Background FIRST
    if (this.bgImg.complete) {
      this.ctx.drawImage(this.bgImg, 0, 0, 400, 600);
    }
    this.pipes.forEach(pipe => {

      // 🔼 TOP PIPE (flipped)
      this.ctx.save();

      // Move origin to center of where top pipe should be
      this.ctx.translate(
        pipe.x + this.pipeWidth / 2,
        pipe.topHeight / 2
      );

      // Flip vertically
      this.ctx.scale(1, -1);

      this.ctx.drawImage(
        this.pipeBottomImg, // reuse bottom image
        -this.pipeWidth / 2,
        -pipe.topHeight / 2,
        this.pipeWidth,
        pipe.topHeight
      );

      this.ctx.restore();

      // 🔽 BOTTOM PIPE (normal)
      this.ctx.drawImage(
        this.pipeBottomImg,
        pipe.x,
        pipe.bottomY,
        this.pipeWidth,
        600 - pipe.bottomY
      );
    });

    // 3️⃣ Bird
    this.ctx.drawImage(
      this.birdImg,
      this.bird.x,
      this.bird.y,
      this.bird.width,
      this.bird.height
    );

    // 4️⃣ Score
    this.ctx.fillStyle = 'black';
    this.ctx.font = '24px Arial';
    this.ctx.fillText(`Incidents avoided: ${this.score}`, 20, 40);


  }

  gameLoop() {
    this.update();
    this.draw();
    requestAnimationFrame(() => this.gameLoop());
  }
}