class_name CardDatabase
extends RefCounted

const CARD_BASE_PATH := "res://assets/cards/"

const STAT_KEYS: Array[String] = ["passion", "intuition", "curiosity", "comfort"]

const CARDS: Array[Dictionary] = [
  {
    "id": 0,
    "file": "0. The Fool.png",
    "name_en": "The Fool",
    "name_zh": "愚者",
    "upright_pips": [
      1,
      2,
      5
    ],
    "reversed_pips": [
      3,
      4,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "is_highest",
                  "stat": "curiosity"
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": {
                  "type": "is_lowest",
                  "stat": "passion"
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": -1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: if Curiosity is highest, Passion +1; if Passion is lowest, Curiosity -1.",
        "mark_text_zh": "每三次抉择：若奇最高，热+1；若热最低，奇-1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "on_acquire",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              }
            ]
          },
          {
            "timing": "when_refuse",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": -1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "On acquire: Passion +1. Whenever you refuse: Comfort -1.",
        "mark_text_zh": "获得时立即热+1；此后每次你拒绝，逸-1。"
      }
    }
  },
  {
    "id": 1,
    "file": "1. The Magician.png",
    "name_en": "The Magician",
    "name_zh": "魔术师",
    "upright_pips": [
      1,
      2,
      3
    ],
    "reversed_pips": [
      4,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -1,
                    "low_delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: highest stat -1, lowest stat +1.",
        "mark_text_zh": "每三次抉择：将最高属性-1、最低属性+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 3,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "passion",
                  "value": 3
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: if Passion <= 3, Intuition +1 (3 per run).",
        "mark_text_zh": "当你接受时，若热≤3，觉+1（每局三次）。"
      }
    }
  },
  {
    "id": 2,
    "file": "2. The Priestess.png",
    "name_en": "The Priestess",
    "name_zh": "女祭司",
    "upright_pips": [
      1,
      3,
      5
    ],
    "reversed_pips": [
      2,
      4,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_least",
                  "stat": "intuition",
                  "value": 8
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": -1
                  }
                ]
              },
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "intuition",
                  "value": 7
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Intuition +1; if Intuition >= 8, Curiosity -1 instead.",
        "mark_text_zh": "每三次抉择：觉+1；若觉≥8，改为奇-1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 3,
            "rules": [
              {
                "condition": {
                  "type": "is_lowest",
                  "stat": "comfort"
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: if Comfort is lowest, Intuition +1 (3 per run).",
        "mark_text_zh": "每次你拒绝，若逸最低，觉+1（每局三次）。"
      }
    }
  },
  {
    "id": 3,
    "file": "3. The Empress.png",
    "name_en": "The Empress",
    "name_zh": "皇后",
    "upright_pips": [
      1,
      2,
      3,
      4
    ],
    "reversed_pips": [
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_least",
                  "stat": "comfort",
                  "value": 8
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "comfort",
                  "value": 7
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Comfort +1; if Comfort >= 8, Passion +1 instead.",
        "mark_text_zh": "每三次抉择：逸+1；若逸≥8，改为热+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "on_acquire",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              }
            ]
          },
          {
            "timing": "when_accept",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "comfort",
                  "value": 3
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "On acquire: Comfort +1. Whenever you accept: if Comfort <= 3, Curiosity +1.",
        "mark_text_zh": "获得时立即逸+1；此后每当你接受，若逸≤3，奇+1。"
      }
    }
  },
  {
    "id": 4,
    "file": "4. The Emperor.png",
    "name_en": "The Emperor",
    "name_zh": "皇帝",
    "upright_pips": [
      2,
      3,
      4
    ],
    "reversed_pips": [
      1,
      5,
      6
    ],
    "special": "emperor",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [],
        "mark_text_en": "Once per run: when any stat would be <=0 or >=10, set it to 1 or 9.",
        "mark_text_zh": "每局一次：任一属性将≤0或≥10时，改为1或9。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          }
        ],
        "effects": [],
        "mark_text_en": "Once per run: when any stat would be <=0 or >=10, set it to 1 or 9; after triggering, Intuition -1.",
        "mark_text_zh": "每局一次：任一属性将≤0或≥10时，改为1或9；触发后觉-1。"
      }
    }
  },
  {
    "id": 5,
    "file": "5. The Hierophant.png",
    "name_en": "The Hierophant",
    "name_zh": "教皇",
    "upright_pips": [
      1,
      2,
      3
    ],
    "reversed_pips": [
      4,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "marks_at_least",
                  "value": 3
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Intuition +1; if you have at least 3 marks, Passion +1 instead.",
        "mark_text_zh": "每三次抉择：觉+1；若已有至少3个印记，改为热+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: Intuition +1 (3 per run).",
        "mark_text_zh": "每次你拒绝，觉+1（每局最多三次）。"
      }
    }
  },
  {
    "id": 6,
    "file": "6. The Lovers.png",
    "name_en": "The Lovers",
    "name_zh": "恋人",
    "upright_pips": [
      1,
      2,
      5
    ],
    "reversed_pips": [
      3,
      4,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "is_lowest",
                  "stat": "passion"
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Comfort +1; if Passion is lowest, Passion +1 instead.",
        "mark_text_zh": "每三次抉择：逸+1；若热最低，改为热+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 3,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "curiosity",
                  "value": 3
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: if Curiosity <= 3, Comfort +1 (3 per run).",
        "mark_text_zh": "当你接受时，若奇≤3，逸+1（每局三次）。"
      }
    }
  },
  {
    "id": 7,
    "file": "7. The Chariot.png",
    "name_en": "The Chariot",
    "name_zh": "战车",
    "upright_pips": [
      1,
      2,
      3,
      4
    ],
    "reversed_pips": [
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_least",
                  "stat": "passion",
                  "value": 8
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "passion",
                  "value": 7
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Passion +1; if Passion >= 8, Curiosity +1 instead.",
        "mark_text_zh": "每三次抉择：热+1；若热≥8，改为奇+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: Passion +1 (3 per run).",
        "mark_text_zh": "每次你接受，热+1（每局最多三次）。"
      }
    }
  },
  {
    "id": 8,
    "file": "8. Justice.png",
    "name_en": "Justice",
    "name_zh": "正义",
    "upright_pips": [
      1,
      2,
      3
    ],
    "reversed_pips": [
      4,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -1,
                    "low_delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: highest stat -1, lowest stat +1.",
        "mark_text_zh": "每三次抉择：将最高属性-1、最低属性+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 2,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -1,
                    "low_delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: highest stat -1, lowest stat +1 (2 per run).",
        "mark_text_zh": "每次你拒绝，将最高属性-1、最低属性+1（每局两次）。"
      }
    }
  },
  {
    "id": 9,
    "file": "9. The Hermit.png",
    "name_en": "The Hermit",
    "name_zh": "隐者",
    "upright_pips": [
      1,
      3,
      5
    ],
    "reversed_pips": [
      2,
      4,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "refusals_at_least",
                  "value": 3
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Intuition +1; if you have refused at least 3 times, Comfort +1 instead.",
        "mark_text_zh": "每三次抉择：觉+1；若已拒绝过至少3次，改为逸+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: Curiosity +1 (3 per run).",
        "mark_text_zh": "每次你拒绝，奇+1（每局三次）。"
      }
    }
  },
  {
    "id": 10,
    "file": "10. Wheel of Fortune.png",
    "name_en": "Wheel of Fortune",
    "name_zh": "命运之轮",
    "upright_pips": [
      1,
      4,
      6
    ],
    "reversed_pips": [
      2,
      3,
      5
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "any_at_least",
                  "value": 9
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": -1
                  }
                ]
              },
              {
                "condition": {
                  "type": "none_at_least",
                  "value": 9
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Intuition +1; if any stat is >= 9, Intuition -1 instead.",
        "mark_text_zh": "每三次抉择：觉+1；若任意属性≥9，改为觉-1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  },
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": -1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: Passion +1, Comfort -1 (3 per run).",
        "mark_text_zh": "每次你接受，热+1、逸-1（每局三次）。"
      }
    }
  },
  {
    "id": 11,
    "file": "11. Strength.png",
    "name_en": "Strength",
    "name_zh": "力量",
    "upright_pips": [
      1,
      2,
      3,
      4
    ],
    "reversed_pips": [
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "passion",
                  "value": 3
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Passion +1; if Passion <= 3, Intuition +1 instead.",
        "mark_text_zh": "每三次抉择：热+1；若热≤3，改为觉+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "once_per_run",
            "limit": 1,
            "rules": [
              {
                "condition": {
                  "type": "any_at_most",
                  "value": 2
                },
                "actions": [
                  {
                    "type": "boost_lowest",
                    "delta": 2
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Once per run: when any stat is <= 2, that stat +2.",
        "mark_text_zh": "每局一次：任一属性≤2时，该属性+2。"
      }
    }
  },
  {
    "id": 12,
    "file": "12. The Hanged Man.png",
    "name_en": "The Hanged Man",
    "name_zh": "倒吊人",
    "upright_pips": [
      2,
      3,
      4
    ],
    "reversed_pips": [
      1,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_least",
                  "stat": "comfort",
                  "value": 8
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "comfort",
                  "value": 7
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Comfort +1; if Comfort >= 8, Intuition +1 instead.",
        "mark_text_zh": "每三次抉择：逸+1；若逸≥8，改为觉+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: Intuition +1 (3 per run).",
        "mark_text_zh": "每次你拒绝，觉+1（每局三次）。"
      }
    }
  },
  {
    "id": 13,
    "file": "13. Death.png",
    "name_en": "Death",
    "name_zh": "死神",
    "upright_pips": [
      4,
      5,
      6
    ],
    "reversed_pips": [
      1,
      2,
      3
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 2,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -1,
                    "low_delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: highest stat -1 and lowest stat +1 (2 per run).",
        "mark_text_zh": "每次你接受：最高属性-1、最低属性+1（每局两次）。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "passion",
                    "delta": 1
                  },
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": -1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Passion +1, Intuition -1.",
        "mark_text_zh": "每三次抉择：热+1，但触发时觉-1。"
      }
    }
  },
  {
    "id": 14,
    "file": "14. Temperance.png",
    "name_en": "Temperance",
    "name_zh": "节制",
    "upright_pips": [
      1,
      2,
      3
    ],
    "reversed_pips": [
      4,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -1,
                    "low_delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: highest stat -1, lowest stat +1.",
        "mark_text_zh": "每三次抉择：将最高属性-1、最低属性+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 2,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -1,
                    "low_delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: highest stat -1, lowest stat +1 (2 per run).",
        "mark_text_zh": "每次你拒绝，将最高属性-1、最低属性+1（每局两次）。"
      }
    }
  },
  {
    "id": 15,
    "file": "15. The Devil.png",
    "name_en": "The Devil",
    "name_zh": "恶魔",
    "upright_pips": [
      5,
      6
    ],
    "reversed_pips": [
      1,
      2,
      3,
      4
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": 2
                  },
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": -1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Curiosity +2, Comfort -1.",
        "mark_text_zh": "每三次抉择：奇+2，但逸-1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": 2
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 2,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": 2
                  },
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": -1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: Curiosity +2, Comfort -1 (2 per run).",
        "mark_text_zh": "每次你接受，奇+2，但逸-1（每局两次）。"
      }
    }
  },
  {
    "id": 16,
    "file": "16. The Star.png",
    "name_en": "The Star",
    "name_zh": "星星",
    "upright_pips": [
      1,
      2,
      3,
      4
    ],
    "reversed_pips": [
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "stat_at_least",
                  "stat": "intuition",
                  "value": 8
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": {
                  "type": "stat_at_most",
                  "stat": "intuition",
                  "value": 7
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Intuition +1; if Intuition >= 8, Comfort +1 instead.",
        "mark_text_zh": "每三次抉择：觉+1；若觉≥8，改为逸+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: Intuition +1 (3 per run).",
        "mark_text_zh": "每次你拒绝，觉+1（每局三次）。"
      }
    }
  },
  {
    "id": 17,
    "file": "17. The Tower.png",
    "name_en": "The Tower",
    "name_zh": "高塔",
    "upright_pips": [
      1
    ],
    "reversed_pips": [
      2,
      3,
      4,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "on_acquire",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "set_all",
                    "value": 5
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "On acquire: set all stats to 5.",
        "mark_text_zh": "获得时立即：所有属性重置为5。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "on_acquire",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "shift_extremes",
                    "high_delta": -2,
                    "low_delta": 2
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "On acquire: highest stat -2 and lowest stat +2.",
        "mark_text_zh": "获得时立即：最高属性-2、最低属性+2。"
      }
    }
  },
  {
    "id": 18,
    "file": "18. The Moon.png",
    "name_en": "The Moon",
    "name_zh": "月亮",
    "upright_pips": [
      1,
      4,
      6
    ],
    "reversed_pips": [
      2,
      3,
      5
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "is_lowest",
                  "stat": "intuition"
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "curiosity",
                    "delta": 1
                  }
                ]
              },
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: Intuition +1; if Intuition is lowest, Curiosity +1 instead.",
        "mark_text_zh": "每三次抉择：觉+1；若觉最低，改为奇+1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_refuse",
            "limit": 3,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "stat",
                    "stat": "comfort",
                    "delta": 1
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you refuse: Comfort +1 (3 per run).",
        "mark_text_zh": "每次你拒绝，逸+1（每局三次）。"
      }
    }
  },
  {
    "id": 19,
    "file": "19. The Sun.png",
    "name_en": "The Sun",
    "name_zh": "太阳",
    "upright_pips": [
      1,
      2,
      3,
      4,
      5
    ],
    "reversed_pips": [
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "all",
            "delta": 1,
            "cap": 9
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "every_3",
            "limit": 0,
            "rules": [
              {
                "condition": {
                  "type": "any_at_least",
                  "value": 9
                },
                "actions": [
                  {
                    "type": "stat",
                    "stat": "intuition",
                    "delta": -1
                  }
                ]
              },
              {
                "condition": {
                  "type": "none_at_least",
                  "value": 9
                },
                "actions": [
                  {
                    "type": "all",
                    "delta": 1,
                    "cap": 9
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Every 3 choices: all stats +1 (max 9); if any stat is >= 9, Intuition -1 instead.",
        "mark_text_zh": "每三次抉择：所有属性+1（不超过9）；若任意属性≥9，改为觉-1。"
      },
      "reversed": {
        "accept": [
          {
            "type": "all",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 2
          },
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "when_accept",
            "limit": 2,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "all",
                    "delta": 1,
                    "cap": 9
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Whenever you accept: all stats +1 (max 9) (2 per run).",
        "mark_text_zh": "每次你接受，所有属性+1（不超过9）（每局两次）。"
      }
    }
  },
  {
    "id": 20,
    "file": "20. Judgement.png",
    "name_en": "Judgement",
    "name_zh": "审判",
    "upright_pips": [
      1,
      2,
      3
    ],
    "reversed_pips": [
      4,
      5,
      6
    ],
    "special": "",
    "orientations": {
      "upright": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "comfort",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "final",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "set_stat",
                    "stat": "passion",
                    "value": 5
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Final: set any one stat to 5.",
        "mark_text_zh": "终局：你可以将任意一项属性直接设为5。"
      },
      "reversed": {
        "accept": [
          {
            "type": "stat",
            "stat": "intuition",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": 1
          }
        ],
        "refuse": [
          {
            "type": "stat",
            "stat": "curiosity",
            "delta": 1
          },
          {
            "type": "stat",
            "stat": "comfort",
            "delta": -1
          },
          {
            "type": "stat",
            "stat": "passion",
            "delta": -1
          }
        ],
        "effects": [
          {
            "timing": "final",
            "limit": 0,
            "rules": [
              {
                "condition": null,
                "actions": [
                  {
                    "type": "set_stat",
                    "stat": "passion",
                    "value": 5
                  }
                ]
              }
            ]
          }
        ],
        "mark_text_en": "Final: set any one stat to 5; if you die in the final check, the Emperor cannot save you.",
        "mark_text_zh": "终局：你可以将任意一项属性直接设为5；但终局死亡时皇帝不能救。"
      }
    }
  },
  {
    "id": 21,
    "file": "21. The World.png",
    "name_en": "The World",
    "name_zh": "世界",
    "upright_pips": [],
    "reversed_pips": [],
    "special": "world",
    "orientations": {
      "upright": null,
      "reversed": null
    }
  }
]


static func get_card(id: int) -> Dictionary:
	if id < 0 or id >= CARDS.size():
		return {}
	return CARDS[id]


static func texture_path(id: int) -> String:
	var card := get_card(id)
	if card.is_empty():
		return ""
	return CARD_BASE_PATH + str(card["file"])


static func card_name(id: int) -> String:
	var card := get_card(id)
	if card.is_empty():
		return "Unknown"
	return str(card["name_en"])


static func orientation_data(id: int, orientation: String) -> Dictionary:
	var card := get_card(id)
	if card.is_empty():
		return {}
	var orientations: Dictionary = card.get("orientations", {})
	return orientations.get(orientation, {})
