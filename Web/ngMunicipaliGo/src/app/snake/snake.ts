import { CommonModule } from '@angular/common';
import { Component, HostListener, OnInit, Output, EventEmitter } from '@angular/core';

interface Position {
  x: number;
  y: number;
}

@Component({
  selector: 'app-snake-overlay',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './snake.html',
  styleUrls: ['./snake.css']
})
export class SnakeOverlayComponent implements OnInit {

  @Output() closed = new EventEmitter<void>();

  gridSize = 15;
  tileSize = 40;
  snake: Position[] = [];
  food!: Position;
  direction: Position = { x: 1, y: 0 };
  interval: any;
  speed = 150;
  score = 0;
  gameOver = false;

  ngOnInit() {
    this.startGame();
  }
  headSize = 40;
  foodSize = 40;
  segmentSize = 40;

  getHeadTransform(pos: Position) {
    return `translate(${pos.x * this.tileSize}px, ${pos.y * this.tileSize}px)`;
  }

  getSegmentTransform(pos: Position) {
    return `translate(${pos.x * this.tileSize}px, ${pos.y * this.tileSize}px)`;
  }

  getFoodTransform() {
    return `translate(${this.food.x * this.tileSize}px, ${this.food.y * this.tileSize}px)`;
  }

  startGame() {
    this.snake = [
      { x: 2, y: 0 },
      { x: 1, y: 0 },
      { x: 0, y: 0 }
    ];
    this.direction = { x: 1, y: 0 };
    this.score = 0;
    this.gameOver = false;
    this.generateObstacles();
    this.generateFood();


    console.log("FOOD:", this.food);

    clearInterval(this.interval);
    this.interval = setInterval(() => this.move(), this.speed);
  }

  generateObstacles() {
    this.obstacles = [];

    while (this.obstacles.length < this.obstacleCount) {
      const newObstacle = {
        x: Math.floor(Math.random() * this.gridSize),
        y: Math.floor(Math.random() * this.gridSize)
      };

      const collisionWithSnake = this.snake.some(
        s => s.x === newObstacle.x && s.y === newObstacle.y
      );

      const collisionWithFood =
        this.food &&
        this.food.x === newObstacle.x &&
        this.food.y === newObstacle.y;

      const collisionWithObstacle = this.obstacles.some(
        o => o.x === newObstacle.x && o.y === newObstacle.y
      );

      if (!collisionWithSnake && !collisionWithFood && !collisionWithObstacle) {
        this.obstacles.push(newObstacle);
      }
    }
  }

  obstacles: Position[] = [];
  obstacleCount = 5; // combien tu veux
  generateFood() {
 let newFood: Position = { x: 0, y: 0 };
  let validPosition = false;

   


  while (!validPosition) {
    newFood = {
      x: Math.floor(Math.random() * (this.gridSize - 2)) + 1,
      y: Math.floor(Math.random() * (this.gridSize - 2)) + 1
    };

    const onSnake = this.snake.some(
      segment => segment.x === newFood.x && segment.y === newFood.y
    );

    const onObstacle = this.obstacles.some(
      obstacle => obstacle.x === newFood.x && obstacle.y === newFood.y
    );

    validPosition = !onSnake && !onObstacle;
  }

  this.food = newFood;
}

  move() {
    if (this.gameOver) return;

    const head = {
      x: this.snake[0].x + this.direction.x,
      y: this.snake[0].y + this.direction.y
    };

    const hitObstacle = this.obstacles.some(
      o => o.x === head.x && o.y === head.y
    );


    if (
      head.x < 0 || head.x >= this.gridSize ||
      head.y < 0 || head.y >= this.gridSize ||
      this.snake.some(s => s.x === head.x && s.y === head.y) ||
      hitObstacle
    ) {
      this.gameOver = true;
      clearInterval(this.interval);
      return;
    }

    this.snake.unshift(head);

    if (head.x === this.food.x && head.y === this.food.y) {
      this.score++;
      this.generateFood();
    } else {
      this.snake.pop();
    }
  }

  @HostListener('window:keydown', ['$event'])
  handleKey(event: KeyboardEvent) {
    switch (event.key) {
      case 'ArrowUp':
        if (this.direction.y === 0) this.direction = { x: 0, y: -1 };
        break;
      case 'ArrowDown':
        if (this.direction.y === 0) this.direction = { x: 0, y: 1 };
        break;
      case 'ArrowLeft':
        if (this.direction.x === 0) this.direction = { x: -1, y: 0 };
        break;
      case 'ArrowRight':
        if (this.direction.x === 0) this.direction = { x: 1, y: 0 };
        break;
    }
  }

  getTransform(pos: Position) {
    return `translate(${pos.x * this.tileSize}px, ${pos.y * this.tileSize}px)`;
  }

  close() {
    clearInterval(this.interval);
    this.closed.emit();
  }
}